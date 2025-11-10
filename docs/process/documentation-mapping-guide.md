# Documentation Mapping Guide for Story Preparation

**Version:** 1.0
**Created:** 2025-11-10
**Owner:** Winston (Architect)
**For:** Bob (Scrum Master) - Story Preparation Reference

---

## Purpose

This guide maps **story types** and **technical domains** to relevant documentation in the `/docs` tree. Use this when populating the `<implementation-guidance>` section of Story Context XMLs.

---

## Universal Documentation (ALL Stories)

These documents apply to **every story** regardless of type:

### Architecture Decision Records
```xml
<adr priority="HIGH">
  <number>ADR-0002</number>
  <path>docs/architecture/adr/ADR-0002-flutter-serverpod-architecture.md</path>
  <decision>Flutter + Serverpod stack</decision>
  <reason>Foundational architecture all features build upon</reason>
  <applies-to>ALL</applies-to>
</adr>
<adr priority="HIGH">
  <number>ADR-0006</number>
  <path>docs/architecture/adr/ADR-0006-modular-monolith.md</path>
  <decision>Modular monolith with clear boundaries</decision>
  <reason>Package structure and module organization principles</reason>
  <applies-to>ALL</applies-to>
</adr>
```

### Core Architecture
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/coding-standards.md</path>
    <section>ALL</section>
    <reason>Code style, naming conventions, and quality standards</reason>
    <applies-to>ALL</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/pattern-library.md</path>
    <section>{relevant-pattern-section}</section>
    <reason>Reusable patterns for common implementation challenges</reason>
    <applies-to>{specific-tasks}</applies-to>
  </doc>
</architecture>
```

---

## By Technical Domain

### Domain: Authentication & Authorization

**Applies to:** Epic 1 stories, any auth-related features

#### CRITICAL Priority
```xml
<adr priority="CRITICAL">
  <number>ADR-0009</number>
  <path>docs/architecture/adr/ADR-0009-security-architecture.md</path>
  <decision>Comprehensive security architecture including OTP, JWT, encryption</decision>
  <reason>Security requirements are non-negotiable</reason>
  <applies-to>ALL</applies-to>
</adr>
<architecture>
  <doc priority="CRITICAL">
    <path>docs/architecture/serverpod-auth-module-analysis.md</path>
    <section>ALL</section>
    <reason>Serverpod auth module capabilities and limitations</reason>
    <applies-to>ALL</applies-to>
  </doc>
</architecture>
<framework priority="CRITICAL">
  <name>Serverpod</name>
  <path>docs/frameworks/serverpod/05-authentication-sessions.md</path>
  <section>ALL</section>
  <reason>Serverpod authentication and session management patterns</reason>
  <applies-to>ALL</applies-to>
</framework>
```

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/serverpod-integration-guide.md</path>
    <section>Authentication Endpoints</section>
    <reason>Standard Serverpod endpoint patterns for auth</reason>
    <applies-to>{backend-tasks}</applies-to>
  </doc>
</architecture>
<pattern priority="HIGH">
  <path>docs/architecture/pattern-library.md</path>
  <section>Authentication Patterns</section>
  <reason>Standard patterns for OTP, token management, session handling</reason>
  <applies-to>{auth-specific-tasks}</applies-to>
</pattern>
<runbook priority="HIGH">
  <path>docs/runbooks/authentication.md</path>
  <section>ALL</section>
  <reason>Auth operational procedures and troubleshooting</reason>
  <applies-to>ALL</applies-to>
</runbook>
```

---

### Domain: State Management (BLoC)

**Applies to:** All Flutter UI stories with state

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/bloc-implementation-guide.md</path>
    <section>{relevant-section}</section>
    <reason>BLoC patterns, event/state design, repository integration</reason>
    <applies-to>{frontend-tasks}</applies-to>
  </doc>
</architecture>
<adr priority="HIGH">
  <number>ADR-0007</number>
  <path>docs/architecture/adr/ADR-0007-state-management.md</path>
  <decision>BLoC for state management</decision>
  <reason>State management approach and rationale</reason>
  <applies-to>{frontend-tasks}</applies-to>
</adr>
<framework priority="HIGH">
  <name>BLoC</name>
  <path>docs/frameworks/bloc-integration-guide.md</path>
  <section>ALL</section>
  <reason>Flutter BLoC integration patterns and best practices</reason>
  <applies-to>{frontend-tasks}</applies-to>
</framework>
```

---

### Domain: Database & Persistence

**Applies to:** Stories with database queries, models, migrations

#### CRITICAL Priority
```xml
<adr priority="CRITICAL">
  <number>ADR-0003</number>
  <path>docs/architecture/adr/ADR-0003-database-architecture.md</path>
  <decision>PostgreSQL with specific schema design decisions</decision>
  <reason>Database architecture and design principles</reason>
  <applies-to>{backend-tasks}</applies-to>
</adr>
```

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/database-indexing-strategy.md</path>
    <section>{relevant-indexes}</section>
    <reason>Index design for query performance</reason>
    <applies-to>{query-tasks}</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/serverpod-integration-guide.md</path>
    <section>Database Models and Migrations</section>
    <reason>Serverpod model definition and migration workflow</reason>
    <applies-to>{model-tasks}</applies-to>
  </doc>
</architecture>
<framework priority="HIGH">
  <name>PostgreSQL</name>
  <path>docs/frameworks/postgresql-patterns-guide.md</path>
  <section>ALL</section>
  <reason>PostgreSQL-specific patterns and optimizations</reason>
  <applies-to>{database-tasks}</applies-to>
</framework>
<runbook priority="HIGH">
  <path>docs/runbooks/code-generation-workflow.md</path>
  <section>Database Migrations</section>
  <reason>Migration generation and application procedures</reason>
  <applies-to>{migration-tasks}</applies-to>
</runbook>
```

#### MEDIUM Priority
```xml
<architecture>
  <doc priority="MEDIUM">
    <path>docs/architecture/database-performance-audit-plan.md</path>
    <section>ALL</section>
    <reason>Performance monitoring and optimization strategies</reason>
    <applies-to>{query-optimization-tasks}</applies-to>
  </doc>
</architecture>
```

---

### Domain: API Endpoints

**Applies to:** Stories creating or modifying Serverpod endpoints

#### HIGH Priority
```xml
<adr priority="HIGH">
  <number>ADR-0008</number>
  <path>docs/architecture/adr/ADR-0008-api-design.md</path>
  <decision>RESTful API design principles</decision>
  <reason>API contract and design standards</reason>
  <applies-to>{endpoint-tasks}</applies-to>
</adr>
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/serverpod-integration-guide.md</path>
    <section>Endpoint Development</section>
    <reason>Serverpod endpoint patterns and best practices</reason>
    <applies-to>{endpoint-tasks}</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/api-gateway-routing-design.md</path>
    <section>{relevant-routes}</section>
    <reason>API gateway routing and middleware configuration</reason>
    <applies-to>{routing-tasks}</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/openapi-spec.yaml</path>
    <section>{relevant-endpoints}</section>
    <reason>API contract specifications</reason>
    <applies-to>{endpoint-tasks}</applies-to>
  </doc>
</architecture>
<framework priority="HIGH">
  <name>Serverpod</name>
  <path>docs/frameworks/serverpod/README.md</path>
  <section>Endpoints</section>
  <reason>Serverpod endpoint framework guide</reason>
  <applies-to>{endpoint-tasks}</applies-to>
</framework>
```

---

### Domain: Payments (Stripe)

**Applies to:** Epic 12 stories and payment-related features

#### CRITICAL Priority
```xml
<adr priority="CRITICAL">
  <number>ADR-0004</number>
  <path>docs/architecture/adr/ADR-0004-payment-processing.md</path>
  <decision>Stripe integration architecture</decision>
  <reason>Payment processing requirements and security</reason>
  <applies-to>ALL</applies-to>
</adr>
<security>
  <requirement priority="CRITICAL">
    <path>docs/architecture/adr/ADR-0009-security-architecture.md</path>
    <section>Payment Security Requirements</section>
    <applies-to>ALL</applies-to>
  </requirement>
</security>
```

#### HIGH Priority
```xml
<framework priority="HIGH">
  <name>Stripe</name>
  <path>docs/frameworks/stripe-integration-guide.md</path>
  <section>ALL</section>
  <reason>Stripe API integration patterns and best practices</reason>
  <applies-to>ALL</applies-to>
</framework>
<runbook priority="HIGH">
  <path>docs/runbooks/stripe-payments.md</path>
  <section>ALL</section>
  <reason>Payment processing operational procedures</reason>
  <applies-to>ALL</applies-to>
</runbook>
```

---

### Domain: Video Processing & Streaming

**Applies to:** Epics 4, 5, 6, 7 (video capture, processing, streaming)

#### HIGH Priority
```xml
<framework priority="HIGH">
  <name>FFmpeg</name>
  <path>docs/frameworks/ffmpeg-transcoding-guide.md</path>
  <section>ALL</section>
  <reason>Video transcoding and processing patterns</reason>
  <applies-to>{processing-tasks}</applies-to>
</framework>
<framework priority="HIGH">
  <name>HLS</name>
  <path>docs/frameworks/hls-streaming-guide.md</path>
  <section>ALL</section>
  <reason>HLS streaming implementation patterns</reason>
  <applies-to>{streaming-tasks}</applies-to>
</framework>
<framework priority="HIGH">
  <name>Camera</name>
  <path>docs/frameworks/camera-integration-guide.md</path>
  <section>ALL</section>
  <reason>Flutter camera integration patterns</reason>
  <applies-to>{capture-tasks}</applies-to>
</framework>
<framework priority="HIGH">
  <name>Video Player</name>
  <path>docs/frameworks/video-player-integration-guide.md</path>
  <section>ALL</section>
  <reason>Video playback integration patterns</reason>
  <applies-to>{playback-tasks}</applies-to>
</framework>
```

#### MEDIUM Priority
```xml
<framework priority="MEDIUM">
  <name>S3</name>
  <path>docs/frameworks/s3-storage-guide.md</path>
  <section>ALL</section>
  <reason>S3 storage patterns for video assets</reason>
  <applies-to>{storage-tasks}</applies-to>
</framework>
<framework priority="MEDIUM">
  <name>CloudFront</name>
  <path>docs/frameworks/cloudfront-cdn-guide.md</path>
  <section>ALL</section>
  <reason>CDN configuration for video delivery</reason>
  <applies-to>{cdn-tasks}</applies-to>
</framework>
```

---

### Domain: UI/UX Implementation

**Applies to:** All frontend stories

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/design-system.md</path>
    <section>{relevant-components}</section>
    <reason>Design system components and tokens</reason>
    <applies-to>{ui-tasks}</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/front-end-architecture.md</path>
    <section>ALL</section>
    <reason>Frontend architecture patterns and structure</reason>
    <applies-to>{frontend-tasks}</applies-to>
  </doc>
  <doc priority="HIGH">
    <path>docs/architecture/ux-dev-handoff.md</path>
    <section>ALL</section>
    <reason>UX specifications and implementation guidelines</reason>
    <applies-to>{ui-tasks}</applies-to>
  </doc>
</architecture>
<framework priority="HIGH">
  <name>GoRouter</name>
  <path>docs/frameworks/go-router-integration-guide.md</path>
  <section>ALL</section>
  <reason>Navigation and routing patterns</reason>
  <applies-to>{navigation-tasks}</applies-to>
</framework>
```

---

### Domain: Testing

**Applies to:** All stories (testing tasks)

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/testing/testing-strategy.md</path>
    <section>ALL</section>
    <reason>Testing requirements and coverage standards</reason>
    <applies-to>{test-tasks}</applies-to>
  </doc>
</architecture>
```

---

### Domain: Infrastructure & DevOps

**Applies to:** Epic 01 stories and infrastructure changes

#### HIGH Priority
```xml
<adr priority="HIGH">
  <number>ADR-0005</number>
  <path>docs/architecture/adr/ADR-0005-aws-infrastructure.md</path>
  <decision>AWS infrastructure architecture</decision>
  <reason>Cloud infrastructure design and deployment</reason>
  <applies-to>{infra-tasks}</applies-to>
</adr>
<adr priority="HIGH">
  <number>ADR-0010</number>
  <path>docs/architecture/adr/ADR-0010-observability-strategy.md</path>
  <decision>Observability and monitoring approach</decision>
  <reason>Logging, metrics, and monitoring requirements</reason>
  <applies-to>{observability-tasks}</applies-to>
</adr>
<runbook priority="HIGH">
  <path>docs/runbooks/ci-cd-pipeline.md</path>
  <section>ALL</section>
  <reason>CI/CD pipeline configuration and procedures</reason>
  <applies-to>{cicd-tasks}</applies-to>
</runbook>
<runbook priority="HIGH">
  <path>docs/runbooks/local-development-setup.md</path>
  <section>ALL</section>
  <reason>Local development environment setup</reason>
  <applies-to>{dev-env-tasks}</applies-to>
</runbook>
```

#### MEDIUM Priority
```xml
<framework priority="MEDIUM">
  <name>Terraform</name>
  <path>docs/frameworks/terraform-iac-guide.md</path>
  <section>ALL</section>
  <reason>Infrastructure as code patterns</reason>
  <applies-to>{terraform-tasks}</applies-to>
</framework>
<framework priority="MEDIUM">
  <name>Docker</name>
  <path>docs/frameworks/docker-development-guide.md</path>
  <section>ALL</section>
  <reason>Docker containerization patterns</reason>
  <applies-to>{docker-tasks}</applies-to>
</framework>
```

---

### Domain: Observability & Analytics

**Applies to:** Epic 03, Epic 17, observability features

#### HIGH Priority
```xml
<adr priority="HIGH">
  <number>ADR-0010</number>
  <path>docs/architecture/adr/ADR-0010-observability-strategy.md</path>
  <decision>Logging, metrics, and monitoring strategy</decision>
  <reason>Observability requirements and implementation patterns</reason>
  <applies-to>ALL</applies-to>
</adr>
<architecture>
  <doc priority="HIGH">
    <path>docs/analytics.md</path>
    <section>ALL</section>
    <reason>Analytics implementation and event tracking</reason>
    <applies-to>{analytics-tasks}</applies-to>
  </doc>
</architecture>
<runbook priority="HIGH">
  <path>docs/runbooks/log-analysis.md</path>
  <section>ALL</section>
  <reason>Log analysis and troubleshooting procedures</reason>
  <applies-to>{logging-tasks}</applies-to>
</runbook>
<runbook priority="HIGH">
  <path>docs/runbooks/metric-interpretation.md</path>
  <section>ALL</section>
  <reason>Metrics interpretation and alerting</reason>
  <applies-to>{metrics-tasks}</applies-to>
</runbook>
```

#### MEDIUM Priority
```xml
<framework priority="MEDIUM">
  <name>BigQuery</name>
  <path>docs/frameworks/bigquery-analytics-guide.md</path>
  <section>ALL</section>
  <reason>BigQuery analytics patterns</reason>
  <applies-to>{analytics-tasks}</applies-to>
</framework>
```

---

### Domain: Privacy & Compliance

**Applies to:** Epic 03, Epic 16, privacy/compliance features

#### CRITICAL Priority
```xml
<security>
  <requirement priority="CRITICAL">
    <path>docs/compliance/privacy-policy.md</path>
    <section>ALL</section>
    <applies-to>ALL</applies-to>
  </requirement>
  <requirement priority="CRITICAL">
    <path>docs/compliance/compliance-guide.md</path>
    <section>{relevant-regulations}</section>
    <applies-to>ALL</applies-to>
  </requirement>
</security>
<runbook priority="CRITICAL">
  <path>docs/runbooks/dsar-process.md</path>
  <section>ALL</section>
  <reason>Data Subject Access Request procedures</reason>
  <applies-to>{dsar-tasks}</applies-to>
</runbook>
```

#### HIGH Priority
```xml
<runbook priority="HIGH">
  <path>docs/runbooks/consent-management.md</path>
  <section>ALL</section>
  <reason>User consent management procedures</reason>
  <applies-to>{consent-tasks}</applies-to>
</runbook>
<runbook priority="HIGH">
  <path>docs/runbooks/data-classification.md</path>
  <section>ALL</section>
  <reason>Data classification and handling requirements</reason>
  <applies-to>{data-handling-tasks}</applies-to>
</runbook>
```

---

### Domain: Auction/Offers Logic

**Applies to:** Epics 9, 10 (auction mechanics)

#### HIGH Priority
```xml
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/offers-auction-orders-model.md</path>
    <section>ALL</section>
    <reason>Auction domain model and state transitions</reason>
    <applies-to>ALL</applies-to>
  </doc>
</architecture>
<runbook priority="HIGH">
  <path>docs/runbooks/auction-timer.md</path>
  <section>ALL</section>
  <reason>Auction timer operational procedures</reason>
  <applies-to>{timer-tasks}</applies-to>
</runbook>
<runbook priority="HIGH">
  <path>docs/runbooks/offers-submission.md</path>
  <section>ALL</section>
  <reason>Offer submission operational procedures</reason>
  <applies-to>{offer-tasks}</applies-to>
</runbook>
```

---

### Domain: Notifications

**Applies to:** Epic 11 (notifications)

#### HIGH Priority
```xml
<adr priority="HIGH">
  <number>ADR-0012</number>
  <path>docs/architecture/adr/ADR-0012-event-driven-architecture.md</path>
  <decision>Event-driven notification architecture</decision>
  <reason>Notification delivery patterns and event sourcing</reason>
  <applies-to>ALL</applies-to>
</adr>
<architecture>
  <doc priority="HIGH">
    <path>docs/architecture/message-queue-architecture.md</path>
    <section>ALL</section>
    <reason>Message queue patterns for notification delivery</reason>
    <applies-to>{queue-tasks}</applies-to>
  </doc>
</architecture>
```

---

### Domain: Performance Optimization

**Applies to:** Stories with performance requirements

#### MEDIUM Priority
```xml
<architecture>
  <doc priority="MEDIUM">
    <path>docs/architecture/performance-optimization-guide.md</path>
    <section>{relevant-optimization}</section>
    <reason>Performance optimization patterns and benchmarks</reason>
    <applies-to>{performance-tasks}</applies-to>
  </doc>
</architecture>
<runbook priority="MEDIUM">
  <path>docs/runbooks/performance-degradation.md</path>
  <section>ALL</section>
  <reason>Performance monitoring and troubleshooting</reason>
  <applies-to>{performance-tasks}</applies-to>
</runbook>
```

---

## Epic-Specific Mapping Summary

| Epic | Primary Domains | Critical Docs |
|------|----------------|---------------|
| 01 | Infrastructure, DevOps | ADR-0005, CI/CD runbook, local dev setup |
| 02 | UI/UX, Core Services | Design system, front-end architecture |
| 03 | Observability, Privacy | ADR-0010, compliance guide, DSAR runbook |
| 1 | Authentication | ADR-0009, Serverpod auth, security architecture |
| 2 | Verification, Payments | Stripe guide, payment security |
| 3 | Profile, Settings | UI patterns, BLoC guide |
| 4-5 | Video Feed, Playback | Video player guide, HLS streaming |
| 6 | Content Pipeline | FFmpeg, S3 storage, CloudFront |
| 7 | Video Capture/Edit | Camera integration, FFmpeg |
| 8 | Publishing, Moderation | Content workflow patterns |
| 9-10 | Auctions, Offers | Auction model, timer runbook |
| 11 | Notifications | Event-driven architecture, message queue |
| 12 | Payments | ADR-0004, Stripe guide, payment security |
| 13 | Shipping | Shipping integration patterns |
| 14 | Disputes | Dispute resolution patterns |
| 15 | Admin/Moderation | Admin patterns, policy enforcement |
| 16 | Security, Compliance | Security architecture, DSAR, compliance |
| 17 | Analytics | Analytics patterns, BigQuery guide |

---

## Quick Reference: Common Combinations

### Backend API Story
```xml
<implementation-guidance>
  <architecture>
    <doc priority="HIGH">
      <path>docs/architecture/serverpod-integration-guide.md</path>
      <section>Endpoint Development</section>
    </doc>
  </architecture>
  <adr priority="HIGH">
    <number>ADR-0008</number>
    <path>docs/architecture/adr/ADR-0008-api-design.md</path>
  </adr>
  <framework priority="HIGH">
    <name>Serverpod</name>
    <path>docs/frameworks/serverpod/README.md</path>
  </framework>
</implementation-guidance>
```

### Frontend UI Story
```xml
<implementation-guidance>
  <architecture>
    <doc priority="HIGH">
      <path>docs/design-system.md</path>
    </doc>
    <doc priority="HIGH">
      <path>docs/architecture/bloc-implementation-guide.md</path>
    </doc>
  </architecture>
  <adr priority="HIGH">
    <number>ADR-0007</number>
    <path>docs/architecture/adr/ADR-0007-state-management.md</path>
  </adr>
  <framework priority="HIGH">
    <name>BLoC</name>
    <path>docs/frameworks/bloc-integration-guide.md</path>
  </framework>
</implementation-guidance>
```

### Full-Stack Feature Story
Combine both backend and frontend sections above, plus domain-specific docs.

---

## Maintenance

Winston (Architect) maintains this mapping guide. Update when:
- New documentation is created
- ADRs are added
- Framework guides are updated
- Story patterns change

---

## Questions?

Contact Winston (Architect) for documentation mapping questions.
Contact Bob (Scrum Master) for story preparation assistance.

