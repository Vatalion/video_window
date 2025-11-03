# Master Documentation Index

**Last Updated:** 2025-11-03 (Framework docs completed)
**Status:** ✅ COMPREHENSIVE - All Documentation Indexed + 21 Framework Guides Complete

---

## 📋 Core Documents
- [PRD](prd.md) - Product Requirements Document
- [Technical Spec](tech-spec.md) - System Architecture Overview
- [Brief](brief.md) - Project Overview & Business Context

---

## 🔄 Process Documentation
- [Process Hub README](process/README.md) - Central process guide
- [Epic Validation Backlog](process/epic-validation-backlog.md) ✅ 20/20 epics ready
- [Definition of Ready](process/definition-of-ready.md) - Story readiness criteria
- [Definition of Done](process/definition-of-done.md) - Completion checklist
- [Story Approval Workflow](process/story-approval-workflow.md) - Complete lifecycle
- [Stakeholder Approval Tracker](process/stakeholder-approval-tracker.md)
- [Validation Report Template](process/validation-report-template.md)
- [Documentation Maintenance Process](process/documentation-maintenance-process.md)

---

## 📐 Architecture Documentation

### Core Architecture
- [Tech Stack](architecture/tech-stack.md) - Technology decisions
- [Coding Standards](architecture/coding-standards.md) - Code conventions
- [BLoC Implementation Guide](architecture/bloc-implementation-guide.md) - State management patterns
- [Data Flow Mapping](architecture/data-flow-mapping.md) - Layer transformations
- [Package Architecture Requirements](architecture/package-architecture-requirements.md) - PSR1-PSR15
- [Serverpod Integration Guide](architecture/serverpod-integration-guide.md)
- [Greenfield Implementation Guide](architecture/greenfield-implementation-guide.md)
- [Front-End Architecture](architecture/front-end-architecture.md)
- [Source Tree](architecture/source-tree.md) - Project structure
- [Project Structure Implementation](architecture/project-structure-implementation.md)
- [Future Structure Diagram](architecture/future-structure-diagram.md)

### System Design
- [System Integration Maps](architecture/system-integration-maps.md)
- [Offers-Auction-Orders Model](architecture/offers-auction-orders-model.md)
- [API Gateway Routing Design](architecture/api-gateway-routing-design.md)
- [Message Queue Architecture](architecture/message-queue-architecture.md)
- [Package Dependency Governance](architecture/package-dependency-governance.md)
- [Melos Configuration](architecture/melos-configuration.md)

### Performance & Security
- [Performance Optimization Guide](architecture/performance-optimization-guide.md)
- [Database Indexing Strategy](architecture/database-indexing-strategy.md)
- [Database Performance Audit Plan](architecture/database-performance-audit-plan.md)
- [Security Configuration](architecture/security-configuration.md)

### Development Guides
- [Pattern Library](architecture/pattern-library.md)
- [Story Component Mapping](architecture/story-component-mapping.md)
- [UX-Dev Handoff](architecture/ux-dev-handoff.md)
- [Lead Review Notes](architecture/lead-review-notes.md)

### Implementation Examples
- [Authentication Flow](architecture/implementation-examples/authentication-flow.md)

### Architecture Decision Records (ADRs)
- [ADR README](architecture/adr/README.md)
- [ADR-0001: Direction Pivot - Auctions](architecture/adr/ADR-0001-direction-pivot-auctions.md)
- [ADR-0002: Flutter + Serverpod Architecture](architecture/adr/ADR-0002-flutter-serverpod-architecture.md)
- [ADR-0003: Database Architecture](architecture/adr/ADR-0003-database-architecture.md)
- [ADR-0004: Payment Processing](architecture/adr/ADR-0004-payment-processing.md)
- [ADR-0005: AWS Infrastructure](architecture/adr/ADR-0005-aws-infrastructure.md)
- [ADR-0006: Modular Monolith](architecture/adr/ADR-0006-modular-monolith.md)
- [ADR-0007: State Management](architecture/adr/ADR-0007-state-management.md)
- [ADR-0008: API Design](architecture/adr/ADR-0008-api-design.md)
- [ADR-0009: Security Architecture](architecture/adr/ADR-0009-security-architecture.md)
- [ADR-0010: Observability Strategy](architecture/adr/ADR-0010-observability-strategy.md)
- [ADR-0011: API Gateway](architecture/adr/ADR-0011-api-gateway.md)
- [ADR-0012: Event-Driven Architecture](architecture/adr/ADR-0012-event-driven-architecture.md)

---

## 🎯 Technical Specifications (20 Total)

### Foundational Epics
- [Epic 1: Viewer Authentication](tech-spec-epic-1.md)
- [Epic 2: Maker Authentication](tech-spec-epic-2.md)
- [Epic 3: Content Management](tech-spec-epic-3.md)

### Feature Epics (User-Facing)
- [Epic 4: Timeline Feed](tech-spec-epic-4.md)
- [Epic 5: Listing Management](tech-spec-epic-5.md)
- [Epic 6: Story Pages](tech-spec-epic-6.md)
- [Epic 7: Offers](tech-spec-epic-7.md)
- [Epic 8: Auctions](tech-spec-epic-8.md)
- [Epic 9: Publishing Workflow](tech-spec-epic-9.md)
- [Epic 10: Auction Timer](tech-spec-epic-10.md)
- [Epic 11: Notifications](tech-spec-epic-11.md)
- [Epic 12: Payments](tech-spec-epic-12.md)
- [Epic 13: Shipping](tech-spec-epic-13.md)

### Operations Epics
- [Epic 14: Issue Resolution](tech-spec-epic-14.md)
- [Epic 15: Admin Moderation](tech-spec-epic-15.md)
- [Epic 16: Security & Compliance](tech-spec-epic-16.md)
- [Epic 17: Analytics & Reporting](tech-spec-epic-17.md)

---

## 📝 User Stories (77 Total)

### Epic 1: Viewer Authentication (5 stories)
- [1.1: Email/SMS Sign-In](stories/1.1.implement-email-sms-sign-in.md)
- [1.2: Social Sign-In Options](stories/1.2.add-social-sign-in-options.md)
- [1.3: Session Management](stories/1.3.session-management-and-refresh.md)
- [1.4: Account Recovery](stories/1.4.account-recovery-email-only.md)
- [1-1: Bootstrap Repository](stories/1-1-bootstrap-repository-and-flutter-app.md)

### Epic 2: Maker Authentication (4 stories)
- [2.1: Capability Enable Request](stories/2.1.capability-enable-request-flow.md)
- [2.2: Verification within Publish Flow](stories/2.2.verification-within-publish-flow.md)
- [2.3: Payout and Compliance](stories/2.3.payout-and-compliance-activation.md)
- [2.4: Device Trust & Risk Monitoring](stories/2.4.device-trust-and-risk-monitoring.md)

### Epic 3: Content Management (5 stories)
- [3.1: Viewer Profile Management](stories/3.1.viewer-profile-management.md)
- [3.1: Logging & Metrics Implementation](stories/3.1-logging-metrics-implementation.md)
- [3.2: Avatar Media Upload](stories/3.2.avatar-media-upload-system.md)
- [3.2: Privacy & Legal Disclosures](stories/3.2-privacy-legal-disclosures.md)
- [3.3: Privacy Settings & Controls](stories/3.3.privacy-settings-and-controls.md)
- [3.3: Data Retention & Backups](stories/3.3-data-retention-backups.md)
- [3.4: Notification Preferences](stories/3.4.notification-preferences-matrix.md)
- [3.5: Account Settings Management](stories/3.5.account-settings-management.md)

### Epic 4: Timeline Feed (6 stories)
- [4.1: Home Feed Implementation](stories/4.1.home-feed-implementation.md)
- [4.2: Infinite Scroll & Pagination](stories/4.2.infinite-scroll-and-pagination.md)
- [4.3: Video Preloading & Caching](stories/4.3.video-preloading-and-caching-strategy.md)
- [4.4: Feed Performance Optimization](stories/4.4.feed-performance-optimization.md)
- [4.5: Content Recommendation Engine](stories/4.5.content-recommendation-engine-integration.md)
- [4.6: Feed Personalization](stories/4.6.feed-personalization-and-user-preferences.md)

### Epic 5: Listing Management (3 stories)
- [5.1: Story Detail Page](stories/5.1.story-detail-page-implementation.md)
- [5.2: Accessible Playback & Transcripts](stories/5.2.accessible-playback-and-transcripts.md)
- [5.3: Share & Save Functionality](stories/5.3.share-and-save-functionality.md)

### Epic 6: Story Pages (3 stories)
- [6.1: Media Pipeline & Content Protection](stories/6.1.media-pipeline-content-protection.md)
- [6.2: Advanced Video Processing](stories/6.2.advanced-video-processing-and-optimization.md)
- [6.3: Content Security & Anti-Piracy](stories/6.3.content-security-and-anti-piracy-system.md)

### Epic 7: Offers (3 stories)
- [7.1: Maker Story Capture & Editing](stories/7.1.maker-story-capture-editing-tools.md)
- [7.2: Timeline Editing & Captioning](stories/7.2.timeline-editing-and-captioning-implementation.md)
- [7.3: Draft Autosave & Sync](stories/7.3.draft-autosave-and-sync-system.md)

### Epic 8: Auctions (4 stories)
- [8.1: Publishing Workflow](stories/8.1.publishing-workflow-implementation.md)
- [8.2: Content Moderation Pipeline](stories/8.2.content-moderation-pipeline.md)
- [8.3: Publishing Approval Process](stories/8.3.publishing-approval-process.md)
- [8.4: Story Versioning & Rollback](stories/8.4.story-versioning-and-rollback.md)

### Epic 9: Publishing Workflow (4 stories)
- [9.1: Offer Submission Flow](stories/9.1.offer-submission-flow.md)
- [9.2: Server Validation & Auction Trigger](stories/9.2.server-validation-and-auction-trigger.md)
- [9.3: Offer Withdrawal & Cancellation](stories/9.3.offer-withdrawal-and-cancellation.md)
- [9.4: Offer State Management & Audit Trail](stories/9.4.offer-state-management-and-audit-trail.md)

### Epic 10: Auction Timer (4 stories)
- [10.1: Auction Timer State Management](stories/10.1.auction-timer-state-management.md)
- [10.2: Soft Close Extension Logic](stories/10.2.soft-close-extension-logic.md)
- [10.3: Auction State Transitions](stories/10.3.auction-state-transitions.md)
- [10.4: Timer Precision & Synchronization](stories/10.4.timer-precision-and-synchronization.md)

### Epic 11: Notifications (4 stories)
- [11.1: Push Notification Infrastructure](stories/11.1.push-notification-infrastructure.md)
- [11.2: In-App Activity Feed](stories/11.2.in-app-activity-feed.md)
- [11.3: Notification Preferences Management](stories/11.3.notification-preferences-management.md)
- [11.4: Maker-Specific Alerts & SLA](stories/11.4.maker-specific-alerts-sla-notifications.md)

### Epic 12: Payments (4 stories)
- [12.1: Stripe Checkout Integration](stories/12.1.stripe-checkout-integration.md)
- [12.2: Payment Window Enforcement](stories/12.2.payment-window-enforcement.md)
- [12.3: Payment Retry Mechanisms](stories/12.3.payment-retry-mechanisms.md)
- [12.4: Receipt Generation & Storage](stories/12.4.receipt-generation-and-storage.md)

### Epic 13: Shipping (4 stories)
- [13.1: Shipping Address Management](stories/13.1.shipping-address-management.md)
- [13.2: Tracking Integration System](stories/13.2.tracking-integration-system.md)
- [13.3: Delivery Confirmation Flow](stories/13.3.delivery-confirmation-flow.md)
- [13.4: Shipping Issue Resolution](stories/13.4.shipping-issue-resolution.md)

### Epic 14: Issue Resolution (3 stories)
- [14.1: Issue Reporting UI](stories/14.1-issue-reporting-ui.md) - 5 pts
- [14.2: Dispute Workflow](stories/14.2-dispute-workflow.md) - 8 pts
- [14.3: Refund Processing](stories/14.3-refund-processing.md) - 8 pts

### Epic 15: Admin Moderation (3 stories)
- [15.1: Admin Dashboard](stories/15.1-admin-dashboard.md) - 8 pts
- [15.2: Listing Takedown](stories/15.2-listing-takedown.md) - 8 pts
- [15.3: Policy Configuration](stories/15.3-policy-config.md) - 5 pts

### Epic 16: Security & Compliance (3 stories)
- [16.1: Secrets & RBAC](stories/16.1-secrets-rbac.md) - 5 pts
- [16.2: Pen-Test Tracking](stories/16.2-pentest.md) - 5 pts
- [16.3: DSAR Workflows](stories/16.3-dsar.md) - 8 pts

### Epic 17: Analytics & Reporting (3 stories)
- [17.1: Event Schema](stories/17.1-event-schema.md) - 5 pts
- [17.2: KPI Dashboards](stories/17.2-dashboards.md) - 8 pts
- [17.3: Automated Reporting](stories/17.3-reporting.md) - 5 pts

---

## ✅ Validation Reports

### Epic Validation Reports
- [Master Validation Summary](validation-reports/MASTER-VALIDATION-SUMMARY-REPORT.md) ⭐
- [Epic 1 Validation](validation-reports/epic-1-validation-report.md)
- [Epic 01 Validation](validation-reports/epic-01-validation-report.md)
- [Epic 2 Validation](validation-reports/epic-2-validation-report.md)
- [Epic 3 Validation](validation-reports/epic-3-validation-report.md)
- [Epic 4 Validation](validation-reports/epic-4-validation-report.md)
- [Epic 5 Validation](validation-reports/epic-5-validation-report.md)
- [Epics 6-17 Consolidated Validation](validation-reports/epics-6-17-consolidated-validation-report.md)

### Story Validation Reports
- [Consolidated MVP Stories Validation](validation-reports/consolidated-mvp-stories-validation-report.md)
- [Story 1.1 Validation](validation-reports/story-1.1-validation-report.md)
- [Story 1.2 Validation](validation-reports/story-1.2-validation-report.md)
- [Story 1.3 Validation](validation-reports/story-1.3-validation-report.md)
- [Story 1.4 Validation](validation-reports/story-1.4-validation-report.md)
- [Story 2.1 Validation](validation-reports/story-2.1-validation-report.md)
- [Story 2.2 Validation](validation-reports/story-2.2-validation-report.md)
- [Story 2.3-2.4 Validation](validation-reports/story-2.3-2.4-validation-report.md)

### Technical Validation
- [Tech Spec Master Index Validation](validation-reports/tech-spec-master-index-validation-report.md)

---

## 🧪 Testing Documentation
- [Master Test Strategy](testing/master-test-strategy.md) ⭐ Comprehensive testing approach
- [Testing Strategy](testing/testing-strategy.md)
- [Acceptance Criteria Framework](testing/acceptance-criteria-framework.md)
- [Test Strategy Checklist](testing/test-strategy-checklist.md)

---

## 📚 Framework Documentation

### Master Framework Index
- ⭐ [Framework Documentation README](frameworks/README.md) - **21/21 guides complete (100%)**

### Core Development (Priority 1) ✅
- [equatable Integration Guide](frameworks/equatable-integration-guide.md) - Value equality for BLoC
- [dartz Integration Guide](frameworks/dartz-integration-guide.md) - Functional error handling
- [go_router Integration Guide](frameworks/go-router-integration-guide.md) - Declarative navigation
- [freezed Integration Guide](frameworks/freezed-integration-guide.md) - Immutable models
- [json_serializable Guide](frameworks/json-serializable-guide.md) - JSON serialization

### Payment Integration (Priority 2) ✅
- [Stripe Integration Guide](frameworks/stripe-integration-guide.md) - Connect Express, checkout, webhooks

### Media Pipeline (Priority 3) ✅
- [video_player Integration Guide](frameworks/video-player-integration-guide.md) - HLS playback & security
- [camera Integration Guide](frameworks/camera-integration-guide.md) - Video recording
- [HLS Streaming Guide](frameworks/hls-streaming-guide.md) - Adaptive bitrate delivery
- [FFmpeg Transcoding Guide](frameworks/ffmpeg-transcoding-guide.md) - Video processing
- [S3 Storage Guide](frameworks/s3-storage-guide.md) - AWS video storage
- [CloudFront CDN Guide](frameworks/cloudfront-cdn-guide.md) - Global video delivery

### Infrastructure (Priority 6) ✅
- [Docker Development Guide](frameworks/docker-development-guide.md) - Local containers
- [PostgreSQL Patterns Guide](frameworks/postgresql-patterns-guide.md) - Database patterns
- [Redis Patterns Guide](frameworks/redis-patterns-guide.md) - Caching & queues
- [Terraform IaC Guide](frameworks/terraform-iac-guide.md) - Infrastructure provisioning

### Analytics (Priority 5) ✅
- [BigQuery Analytics Guide](frameworks/bigquery-analytics-guide.md) - Data warehouse (post-MVP)

### Serverpod (Backend Framework)
- [Serverpod README](frameworks/serverpod/README.md) - Overview
- [01: Setup & Installation](frameworks/serverpod/01-setup-installation.md)
- [02: Project Structure](frameworks/serverpod/02-project-structure.md)
- [03: Code Generation](frameworks/serverpod/03-code-generation.md)
- [04: Database Migrations](frameworks/serverpod/04-database-migrations.md)
- [05: Authentication & Sessions](frameworks/serverpod/05-authentication-sessions.md)
- [06: Deployment](frameworks/serverpod/06-deployment.md)

---

## 📊 Analytics Dashboards
- [Authentication Dashboard](analytics/authentication-dashboard.md)
- [Maker Access Dashboard](analytics/maker-access-dashboard.md)
- [Offers Dashboard](analytics/offers-dashboard.md)
- [Auction Timer Dashboard](analytics/auction-timer-dashboard.md)
- [Stripe Payments Dashboard](analytics/stripe-payments-dashboard.md)

---

## 📖 Runbooks (Operational Guides)
- [Authentication Runbook](runbooks/authentication.md)
- [Maker Access Runbook](runbooks/maker-access.md)
- [Offers Submission Runbook](runbooks/offers-submission.md)
- [Auction Timer Runbook](runbooks/auction-timer.md)
- [Stripe Payments Runbook](runbooks/stripe-payments.md)

---

## 🔒 Security Documentation
- [Story 1.1 Authentication Security Research](security/story-1.1-authentication-security-research.md)
- [Story 1.1 Implementation Summary](security/story-1.1-implementation-summary.md)

---

## 📋 Compliance
- [Compliance Guide](compliance/compliance-guide.md)
- [Privacy Policy](compliance/privacy-policy.md)

---

## 🚀 Sprint Planning
- [Sprint 01 Plan](sprints/sprint-01/sprint-plan.md)

---

## 📊 Status & Analysis Reports
- [Documentation Maintenance Report](documentation-maintenance-implementation-report.md)
- [Documentation Readiness Final Report](documentation-readiness-final-report.md)
- [Process Alignment Verification](process-alignment-verification.md)
- [Architecture Consolidation Report](architecture-consolidation-report.md)
- [Stories Validation Report](stories-validation-report.md)
- [Epic Validation Pipeline Plan](epic-validation-pipeline-plan.md)
- [Missing Stories Analysis](missing-stories-analysis.md)
- [Master Index Update Report](master-index-update-report.md)
- [BMM Workflow Status](bmm-workflow-status.md)
- [Unified Account Correction Plan](unified-account-correction-plan.md)
- [Unified Account Final Report](unified-account-final-report.md)
- [Story 2025-11-01](story-2025-11-01.md)

---

## 🗄️ Archive
- [Archive README](archive/README.md)
- [Course Correction Change Log](archive/course-correction-change-log.md)
- [Final Documentation Audit Summary](archive/final-documentation-audit-summary.md)
- [Tech Spec Audit Report](archive/TECH-SPEC-AUDIT-REPORT.md)

---

## 📈 Project Metrics

### Documentation Coverage
- **Core Documents:** 3/3 (100%) ✅
- **Process Docs:** 8/8 (100%) ✅
- **Architecture Docs:** 35+ files ✅
- **Tech Specs:** 20/20 (100%) ✅
- **User Stories:** 77 total ✅
- **Validation Reports:** 17 reports ✅
- **Testing Docs:** 4/4 (100%) ✅
- **Framework Guides:** 21/21 (100%) ✅ **NEW - Sprint 1 Ready**
- **Runbooks:** 5 operational guides ✅
- **Analytics Dashboards:** 5 dashboards ✅

### Development Readiness
- **Epic Validation:** 20/20 (100%) ✅
- **Story Approval:** All stories validated ✅
- **Test Strategy:** Complete ✅
- **Architecture:** Fully documented ✅

---

