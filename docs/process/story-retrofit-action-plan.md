# Story Retrofit Action Plan - Implementation Guidance

**Created:** 2025-11-10
**Owner:** Mary (Business Analyst)
**Status:** In Progress

---

## Executive Summary

**Problem:** 75 stories lack `<implementation-guidance>` sections in their Story Context XMLs, resulting in developers not consulting critical architecture documentation during implementation.

**Solution:** Systematic retrofit of existing stories with implementation guidance references using new schema.

**Impact:**
- **Priority 1 (Immediate):** 2 in-progress stories
- **Priority 2 (Before Development):** 2 ready-for-dev stories in current sprint
- **Priority 3 (Planned):** 71 ready-for-dev stories in future sprints

---

## Priority 1: In-Progress Stories (IMMEDIATE ACTION REQUIRED)

These stories are actively being developed. Retrofit immediately to prevent continued development without architectural guidance.

### Story 1-1: Email/SMS Sign-In
- **File:** `docs/stories/1-1-implement-email-sms-sign-in.context.xml`
- **Status:** in-progress
- **Developer:** Amelia
- **Action:** Add `<implementation-guidance>` section immediately
- **Domain:** Authentication, Security, BLoC, Serverpod
- **Critical Docs:**
  - ADR-0009: Security Architecture (CRITICAL)
  - Serverpod auth module analysis (CRITICAL)
  - Serverpod authentication guide (CRITICAL)
  - BLoC implementation guide (HIGH)
  - Pattern library - Authentication (HIGH)
  - Authentication runbook (HIGH)

### Story 1-2: Social Login Integration
- **File:** `docs/stories/1-2-add-social-sign-in-options.context.xml`
- **Status:** in-progress
- **Developer:** Amelia
- **Action:** Add `<implementation-guidance>` section immediately
- **Domain:** Authentication, Security, OAuth, Serverpod
- **Critical Docs:**
  - ADR-0009: Security Architecture (CRITICAL)
  - Serverpod auth module analysis (CRITICAL)
  - Serverpod authentication guide (CRITICAL)
  - OAuth integration patterns (HIGH)
  - Authentication runbook (HIGH)

**⚠️ ACTION:** Bob must update these 2 stories TODAY and notify Amelia to consult the updated Story Context XMLs.

---

## Priority 2: Current Sprint Ready-for-Dev (BEFORE STARTING DEVELOPMENT)

These stories may be picked up in current sprint (Sprint 3). Update before development begins.

### Story 03-3: Data Retention & Backup Procedures
- **File:** `docs/stories/03-3-data-retention-backup-procedures.context.xml`
- **Status:** ready-for-dev
- **Domain:** Privacy, Compliance, Infrastructure
- **Critical Docs:**
  - Compliance guide (CRITICAL)
  - DSAR process runbook (CRITICAL)
  - Data classification runbook (HIGH)
  - Database architecture (HIGH)

### Story 1-3: Session Management & Refresh
- **File:** `docs/stories/1-3-session-management-and-refresh.context.xml`
- **Status:** ready-for-dev
- **Domain:** Authentication, Security, Serverpod
- **Critical Docs:**
  - ADR-0009: Security Architecture (CRITICAL)
  - Serverpod auth module analysis (CRITICAL)
  - Serverpod session management (CRITICAL)
  - Authentication patterns (HIGH)

### Story 1-4: Account Recovery
- **File:** `docs/stories/1-4-account-recovery-email-only.context.xml`
- **Status:** ready-for-dev
- **Domain:** Authentication, Security, Email
- **Critical Docs:**
  - ADR-0009: Security Architecture (CRITICAL)
  - Authentication patterns (HIGH)
  - Email integration patterns (HIGH)

**ACTION:** Bob should update these 3 stories ASAP (within 2 days).

---

## Priority 3: Future Sprint Stories

Update these systematically before they enter sprint planning.

### Epic 2: Maker Onboarding (4 stories)
- **Domain:** Verification, Payments, Security
- **Critical Docs:** Payment security, Stripe guide, compliance
- **Stories:**
  - 2-1: Capability enable request flow
  - 2-2: Verification within publish flow
  - 2-3: Payout and compliance activation
  - 2-4: Device trust and risk monitoring

### Epic 3: Viewer Profile (5 stories)
- **Domain:** Profile, UI/UX, Privacy
- **Critical Docs:** BLoC guide, design system, privacy controls
- **Stories:**
  - 3-1: Viewer profile management
  - 3-2: Avatar media upload
  - 3-3: Privacy settings
  - 3-4: Notification preferences
  - 3-5: Account settings

### Epic 4: Video Feed (6 stories)
- **Domain:** Video Playback, Performance, UI/UX
- **Critical Docs:** Video player guide, HLS streaming, performance optimization
- **Stories:**
  - 4-1: TikTok-style feed
  - 4-2: Infinite scroll pagination
  - 4-3: Video preloading caching
  - 4-4: Feed performance optimization
  - 4-5: Recommendation engine
  - 4-6: Feed personalization

### Epic 5: Story Detail & Playback (3 stories)
- **Domain:** Video Playback, Accessibility, UI/UX
- **Critical Docs:** Video player guide, HLS streaming, accessibility patterns
- **Stories:**
  - 5-1: Story detail page
  - 5-2: Accessible playback transcripts
  - 5-3: Share and save functionality

### Epic 6: Content Pipeline & Security (3 stories)
- **Domain:** Video Processing, Security, Storage
- **Critical Docs:** FFmpeg guide, S3 storage, CloudFront CDN, security architecture
- **Stories:**
  - 6-1: Media pipeline content protection
  - 6-2: Advanced video processing
  - 6-3: Content security anti-piracy

### Epic 7: Video Capture & Editing (3 stories)
- **Domain:** Video Capture, Editing, Storage
- **Critical Docs:** Camera integration, FFmpeg, draft management patterns
- **Stories:**
  - 7-1: Video capture import
  - 7-2: Timeline editing captioning
  - 7-3: Draft autosave sync

### Epic 8: Publishing & Moderation (4 stories)
- **Domain:** Publishing, Moderation, Workflow
- **Critical Docs:** Content workflow patterns, admin patterns
- **Stories:**
  - 8-1: Draft review publishing UI
  - 8-2: Moderation queue admin tools
  - 8-3: Publishing workflow scheduling
  - 8-4: Content versioning rollback

### Epic 9: Offer Submission (4 stories)
- **Domain:** Offers, Auction, Validation
- **Critical Docs:** Offers-auction-orders model, offers submission runbook
- **Stories:**
  - 9-1: Offer entry UI
  - 9-2: Server validation auction trigger
  - 9-3: Offer withdrawal cancellation
  - 9-4: Offer state management audit trail

### Epic 10: Auction Mechanics (4 stories)
- **Domain:** Auction, Timers, State Management
- **Critical Docs:** Auction model, auction timer runbook, event-driven architecture
- **Stories:**
  - 10-1: Auction timer creation
  - 10-2: Soft close extension
  - 10-3: Auction state transitions
  - 10-4: Timer precision synchronization

### Epic 11: Notifications & Alerts (4 stories)
- **Domain:** Notifications, Events, Message Queue
- **Critical Docs:** Event-driven architecture, message queue architecture
- **Stories:**
  - 11-1: Push notification infrastructure
  - 11-2: In-app activity feed
  - 11-3: Notification preferences
  - 11-4: Maker specific alerts

### Epic 12: Payments (4 stories)
- **Domain:** Payments, Stripe, Security
- **Critical Docs:** ADR-0004 Payments, Stripe guide, payment security, stripe runbook
- **Stories:**
  - 12-1: Stripe checkout integration
  - 12-2: Payment window enforcement
  - 12-3: Payment retry mechanisms
  - 12-4: Receipt generation storage

### Epic 13: Shipping & Fulfillment (4 stories)
- **Domain:** Shipping, Tracking, Integration
- **Critical Docs:** Shipping integration patterns, tracking APIs
- **Stories:**
  - 13-1: Shipping address collection
  - 13-2: Tracking number management
  - 13-3: Shipping SLA timers
  - 13-4: Order status visibility

### Epic 14: Dispute Resolution (3 stories)
- **Domain:** Disputes, Refunds, Customer Support
- **Critical Docs:** Dispute resolution patterns, refund processing
- **Stories:**
  - 14-1: Issue reporting
  - 14-2: Dispute workflow
  - 14-3: Refund processing

### Epic 15: Moderation & Compliance (3 stories)
- **Domain:** Admin, Moderation, Policy
- **Critical Docs:** Admin patterns, policy enforcement, compliance guide
- **Stories:**
  - 15-1: Admin portal
  - 15-2: Takedown flow
  - 15-3: Policy config UI

### Epic 16: Security & Compliance Operations (3 stories)
- **Domain:** Security, Compliance, DSAR
- **Critical Docs:** Security architecture, compliance guide, DSAR runbook
- **Stories:**
  - 16-1: Secrets rotation RBAC
  - 16-2: Pentest findings tracking
  - 16-3: Data subject access requests

### Epic 17: Analytics & Reporting (3 stories)
- **Domain:** Analytics, Reporting, BigQuery
- **Critical Docs:** Analytics guide, BigQuery patterns, observability strategy
- **Stories:**
  - 17-1: Event schema instrumentation
  - 17-2: KPI pipeline dashboards
  - 17-3: Reporting stakeholder exports

---

## Execution Strategy

### Phase 1: Immediate (Today)
- [ ] Bob retrofits Story 1-1 (in-progress)
- [ ] Bob retrofits Story 1-2 (in-progress)
- [ ] Bob notifies Amelia of updated Story Context XMLs
- [ ] Amelia reads implementation guidance for both stories

### Phase 2: Sprint 3 Stories (This Week)
- [ ] Bob retrofits Story 03-3 (ready-for-dev)
- [ ] Bob retrofits Story 1-3 (ready-for-dev)
- [ ] Bob retrofits Story 1-4 (ready-for-dev)

### Phase 3: Systematic Retrofit (Next 2 Weeks)
- [ ] Bob works through Epic 2 stories (4 stories)
- [ ] Bob works through Epic 3 stories (5 stories)
- [ ] Bob continues epic-by-epic based on sprint planning priorities

### Phase 4: Ongoing (Standard Process)
- [ ] All new Story Context XMLs include `<implementation-guidance>` (mandatory)
- [ ] Bob uses Winston's Documentation Mapping Guide
- [ ] Stories cannot be marked "ready-for-dev" without implementation guidance

---

## Success Metrics

### Immediate (1 week)
- ✅ 100% of in-progress stories have implementation guidance (2/2)
- ✅ 100% of current sprint ready-for-dev stories have implementation guidance (3/3)

### Short-term (2 weeks)
- ✅ 50% of ready-for-dev stories retrofitted (36/71)
- ✅ All new stories include implementation guidance

### Mid-term (4 weeks)
- ✅ 100% of ready-for-dev stories retrofitted (71/71)
- ✅ Zero stories enter development without implementation guidance

---

## Risks & Mitigations

### Risk 1: Developer confusion from mid-development updates
**Mitigation:** Bob directly notifies Amelia with clear explanation of changes

### Risk 2: Retrofit takes too long, blocks sprint planning
**Mitigation:** Prioritize stories by sprint order, retrofit just-in-time

### Risk 3: Documentation references become stale
**Mitigation:** Winston maintains Documentation Mapping Guide, Bob verifies paths during story prep

### Risk 4: Developers still ignore documentation
**Mitigation:** Make implementation guidance review part of story-done checklist

---

## Communication Plan

### To Amelia (Developer)
**Message:** "Your current stories (1-1, 1-2) have been updated with implementation guidance sections. Please re-read the Story Context XMLs and consult the referenced documentation before continuing implementation. This ensures your work aligns with established patterns and security requirements."

### To Team
**Announcement:** "We've enhanced our Story Context XML schema to include explicit implementation guidance. This connects developers directly to relevant architecture docs, patterns, and runbooks. Bob will retrofit existing stories systematically. All new stories will include this section."

---

## Next Actions

1. **Bob:** Retrofit Story 1-1 and 1-2 immediately (Priority 1)
2. **Bob:** Notify Amelia of updates
3. **Amelia:** Review updated Story Context XMLs and consult referenced docs
4. **Bob:** Schedule Priority 2 retrofits (this week)
5. **Winston:** Update Documentation Mapping Guide as needed
6. **Mary:** Track retrofit completion in sprint-status.yaml

---

## Questions?

Contact Mary (Business Analyst) for retrofit planning questions.
Contact Bob (Scrum Master) for story preparation assistance.
Contact Winston (Architect) for documentation mapping questions.

