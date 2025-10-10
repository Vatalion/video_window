# Story-to-Component Architecture Mapping (MVP)

Status: Draft v0.1 — Derived from PRD v0.1 (2025-09-27) and Analyst Checkpoints through 2025-09-29.

This document maps each PRD story to the concrete technical components that will implement it. Use it as the execution blueprint when spinning up development workstreams, aligning Serverpod backend services, Flutter client modules, and shared infrastructure.

## Architectural Baseline
- Flutter 3.35+ (Dart 3.8+) unified package structure with Melos workspace
- Serverpod 2.9.x monolithic backend with modular packages for bounded contexts
- Unified package architecture with mobile_client, core, shared_models, design_system, features
- Stripe Connect Express, hosted Checkout, webhooks for payments
- Signed HLS media delivery with watermarking and capture deterrence
- Observability via structured logging, metrics, tracing, and alerting defined in PRD NFRs

## Core Components

### Flutter Package Architecture
- **packages/mobile_client/**: Main Flutter app with global BLoCs, navigation, app shell
- **packages/core/**: Data layer (repositories, datasources, services), shared utilities
- **packages/shared_models/**: Serverpod-generated models, type definitions
- **packages/design_system/**: UI components, theming, design tokens, shared widgets
- **packages/features/**: Feature-specific packages with use cases and UI

### Feature Packages
- **features/auth/**: Email/SMS OTP, social sign-in, session management UI
- **features/profile/**: Profile editing, notification preferences, consent surfaces
- **features/feed/**: Home feed list, playback controls, reactions, wishlist toggle
- **features/story/**: Story detail layout, section navigation, playback & transcript UI
- **features/commerce/**: Offer entry, auction UI, checkout flow, payment integration
- **features/shipping/**: Shipping details, tracking, order management
- **features/publishing/**: Timeline editor, publishing workflow, maker dashboard
- **features/notifications/**: In-app inbox, push notification handling, badge counts

### Serverpod Services & Modules
- `identity_service`: Viewer/maker auth, OTP, social login federation, session tokens.
- `maker_access_service`: Invite management, applications, RBAC enforcement, device + 2FA management.
- `profile_service`: Viewer/maker settings, notification/consent preferences, public maker cards.
- `story_service`: ArtifactStory CRUD, section content, publish status, versioning.
- `media_pipeline`: Upload ingestion, transcoding jobs, watermark enforcement, signed URL issuance.
- `offers_service`: Offer submission, eligibility checks, minimum thresholds, cancellation logic.
- `auction_service`: Auction state machine, timers, bid validation, audit trail emission.
- `notification_service`: Preference-aware dispatch across push/email/SMS, activity log persistence.
- `payment_service`: Stripe Checkout session orchestration, webhooks, sale locks, ledger.
- `order_service`: Order lifecycle, fulfillment deadlines, shipment tracking sync, auto-complete.
- `issue_service`: Dispute intake, workflow management, refund orchestration.
- `admin_service`: Admin portal APIs, policy configuration, enforcement actions, audit logs.
- `security_service`: Secrets rotation policies, RBAC audits, pen-test tracking, DSAR automation.
- `analytics_service`: Event schema validation, ETL triggers, KPI aggregation exports.
- `config_service`: Remote config JSON, feature flag definitions, rollout tracking.
- `observability_core`: Structured logging, metrics exporters, tracing instrumentation hooks.

### Shared Infrastructure & Integrations
- GitHub Actions CI (`flutter-ci.yml`), secrets scanning, story-flow scripts.
- Stripe Connect Express (payments, payouts), Stripe webhooks for Checkout/Intent events.
- CDN (CloudFront/Cloudflare) for HLS delivery with signed URL integration.
- Object storage (S3 compatible) for raw uploads and HLS renditions.
- Postgres 15 as primary datastore; Redis (or Serverpod task queue) for timers/queues.
- Notification providers: Firebase/APNs for push, SendGrid/Postmark for email, Twilio for SMS.
- Analytics warehouse (BigQuery/Amplitude) fed via batch exporter.
- Monitoring stack: Prometheus/OpenTelemetry, Grafana dashboards, alerting via PagerDuty.

## Epic-to-Component Mapping

Each table lists the implementing components per story. Components marked with `*` are primary owners; others support the workflow.

### Epic F1 — Environment & CI/CD Enablement
| Story | Components | Notes |
| --- | --- | --- |
| F1.1 Bootstrap Repository and Flutter App | `app_shell*`, `design_system`, `observability_core`, GitHub Actions | Scaffold client/backend, add smoke tests, document setup.
| F1.2 Enforce Story Branching and Scripts | Story flow scripts*, Git hooks, `.bmad-core`, documentation | CI checks for branch naming, Conventional Commits, status workflows.
| F1.3 Configure CI Format/Analyze/Test Gates | GitHub Actions*, cache config, Flutter/Serverpod toolchains | Mirrors local gates; pins versions; exposes troubleshooting docs.
| F1.4 Harden Secrets Management and Release Channels | Secrets manager*, `security_service`, release docs | git-secrets/pre-commit hooks, branch protection, release cadence doc.

### Epic F2 — Core Platform Services
| Story | Components | Notes |
| --- | --- | --- |
| F2.1 Design Tokens and Theming | `design_system*`, `app_shell`, docs | Central theme extension, sample widgets, lint rules.
| F2.2 Navigation Shell and Route Registry | `app_shell*`, `config`, `analytics` | Navigator 2.0 routing, guarded maker routes, route analytics hooks.
| F2.3 Configuration & Feature Flags | `config*`, `config_service`, `app_shell` | Remote JSON pull with local fallback, typed toggles, docs for adding flags.
| F2.4 Telemetry Scaffolding | `analytics*`, `observability_core`, `analytics_service` | Event dispatcher, server ingestion, schema alignment with analytics doc.

### Epic F3 — Observability & Compliance Baseline
| Story | Components | Notes |
| --- | --- | --- |
| F3.1 Structured Logging & Metrics | `observability_core*`, `analytics_service`, infra stack | Logging formatters, tracing IDs, Prometheus exporters, dashboards.
| F3.2 Privacy & Legal Disclosures | `profile`, `app_shell`, legal content store*, `security_service` | Reachable policies, consent capture, escalation runbook docs.
| F3.3 Data Retention & Backup Procedures | `security_service*`, `order_service`, infra automation | Backup schedules, lifecycle rules, DR playbooks, drill cadence.

### Epic 1 — Viewer Authentication & Session Handling
| Story | Components | Notes |
| --- | --- | --- |
| 1.1 Email/SMS Sign-In | `auth*`, `identity_service`, Twilio/SendGrid | OTP flow, secure storage, integration tests.
| 1.2 Social Sign-In | `auth*`, `identity_service`, Apple/Google SDKs | Federated identities, fallback to OTP, analytics.
| 1.3 Session Persistence & Logout | `auth*`, `identity_service`, `config` | Refresh tokens, logout wipe, account recovery path.

### Epic 2 — Maker Authentication & Access Control
| Story | Components | Notes |
| --- | --- | --- |
| 2.1 Maker Invite & Application | `auth`, `maker_studio`, `maker_access_service*`, `admin_service` | Invite lifecycle, application intake, notifications.
| 2.2 RBAC Enforcement | `app_shell`, `maker_studio`, `maker_access_service*`, `security_service` | Role claims, guarded routes, audit logging.
| 2.3 Maker Session Security | `auth`, `maker_access_service*`, device inventory UI | Device list, revoke, optional 2FA, session policies.

### Epic 3 — Profile & Settings Management
| Story | Components | Notes |
| --- | --- | --- |
| 3.1 Viewer Profile Editing | `profile*`, `identity_service`, `profile_service` | Optimistic updates, validations, analytics.
| 3.2 Maker Profile & Shop Settings | `maker_studio*`, `profile_service`, `story_service` | Shop metadata, surfaced on story pages, compliance checks.
| 3.3 Notification & Consent Preferences | `profile*`, `notification_service`, `security_service` | Preference matrix, suppression lists, legal exports.

### Epic 4 — Feed Browsing Experience
| Story | Components | Notes |
| --- | --- | --- |
| 4.1 Feed Query & Render | `feed*`, `story_service`, CDN | Paginated endpoint, autoplay list, prefetching.
| 4.2 Playback Controls | `feed*`, `design_system`, `analytics` | Accessibility controls, analytics events, battery saver mode.
| 4.3 Engagement Hooks | `feed*`, `notification_service`, `profile_service` | Reactions, wishlist storage, sticky "View Story" CTA.

### Epic 5 — Story Detail Playback & Consumption
| Story | Components | Notes |
| --- | --- | --- |
| 5.1 Story Sections & CTA | `story*`, `story_service`, `config` | Structured sections, sticky CTA, motion settings.
| 5.2 Accessible Playback & Transcripts | `story*`, `media_pipeline`, CDN | Caption tracks, transcripts, DRM alignment.
| 5.3 Share & Save | `story*`, `profile_service`, deep link service* | Expiring deep links, wishlist persistence, analytics.

### Epic 6 — Media Pipeline & Content Protection
| Story | Components | Notes |
| --- | --- | --- |
| 6.1 Upload Ingestion Service | `maker_studio`, `media_pipeline*`, object storage | Resumable uploads, virus scanning, encryption.
| 6.2 Transcode to HLS with Watermarking | `media_pipeline*`, transcoder workers, CDN | Renditions, watermark overlays, job status updates.
| 6.3 Signed URLs & Policies | `media_pipeline*`, CDN, `security_service` | Short-lived tokens, revocation, geo/IP enforcement.

### Epic 7 — Maker Story Capture & Editing Tools
| Story | Components | Notes |
| --- | --- | --- |
| 7.1 Capture & Import | `maker_studio*`, device camera APIs, local secure storage | Multi-clip capture, format validation, encryption.
| 7.2 Timeline Editing & Captioning | `maker_studio*`, `design_system`, `analytics` | Timeline UI, caption editor, autosave instrumentation.
| 7.3 Draft Autosave & Sync | `maker_studio*`, `story_service`, offline queue | Version history, conflict resolution, dashboard listing.

### Epic 8 — Story Publishing & Moderation Pipeline
| Story | Components | Notes |
| --- | --- | --- |
| 8.1 Moderation Queue | `maker_studio`, `admin_service*`, `story_service` | Submission workflow, moderator UI, decision logging.
| 8.2 Publishing Approvals & Scheduling | `maker_studio*`, `story_service`, scheduler | Timezone-aware scheduler, prerequisite checks.
| 8.3 Versioning & Rollback | `story_service*`, `admin_service`, object storage | Immutable versions, rollback actions, audit trail.

### Epic 9 — Offer Submission Flow
| Story | Components | Notes |
| --- | --- | --- |
| 9.1 Offer Entry UI & Checks | `offer_bid*`, `offers_service`, `identity_service` | Offer modal, eligibility checks, abandon analytics.
| 9.2 Server Validation & Auction Trigger | `offers_service*`, `auction_service`, `notification_service` | Payment eligibility, auction state init, maker alerts.
| 9.3 Offer Withdrawal & Cancellation | `offer_bid`, `offers_service*`, `auction_service` | Withdrawal rules, history, dashboard sync.

### Epic 10 — Auction Timer & State Management
| Story | Components | Notes |
| --- | --- | --- |
| 10.1 Auction State Machine | `auction_service*`, scheduler, `offers_service` | State transitions, idempotent persistence, event emission.
| 10.2 Soft-Close & Bid Increment Logic | `auction_service*`, `offer_bid`, `auction` UI | Timer extensions, increment enforcement, countdown UI.
| 10.3 Audit Trails & Compliance | `auction_service*`, `security_service`, analytics warehouse | Detailed logs, export endpoints, anomaly alerts.

### Epic 11 — Notifications & Activity Surfaces
| Story | Components | Notes |
| --- | --- | --- |
| 11.1 Notification Service | `notification_service*`, provider SDKs, Redis queue | Template rendering, provider abstraction, retries.
| 11.2 Offer & Auction Notifications | `offer_bid`, `notification_service*`, `auction_service` | Buyer/maker alerts, deep links, countdown context.
| 11.3 Activity Inbox UI | `notifications*`, `notification_service`, `design_system` | Inbox list, filters, read status, accessibility compliance.

### Epic 12 — Checkout & Payment Processing
| Story | Components | Notes |
| --- | --- | --- |
| 12.1 Stripe Checkout Launch | `checkout*`, `payment_service`, Stripe SDK/webhooks | Session creation, hosted page launch, success handling.
| 12.2 24-Hour Payment Window | `checkout*`, `payment_service`, scheduler | Countdown UI, expiration handling, next-bidder logic.
| 12.3 Receipts & Audit Trail | `payment_service*`, `order_service`, ledger database | Receipt emails, ledger entries, failure codes.

### Epic 13 — Shipping & Tracking Management
| Story | Components | Notes |
| --- | --- | --- |
| 13.1 Shipping Details at Checkout | `checkout`, `order_service*`, Stripe | Address collection sync, edit window, validation.
| 13.2 Maker Tracking & Reminders | `orders`, `order_service*`, notification scheduler | SLA timers, tracking form, escalation flow.
| 13.3 Buyer Tracking Visibility | `orders*`, `order_service`, notification service | Tracking timeline, milestone notifications, auto-complete trigger.

### Epic 14 — Issue Resolution & Refund Handling
| Story | Components | Notes |
| --- | --- | --- |
| 14.1 Issue Reporting | `orders*`, `issue_service`, storage | Issue intake UI, evidence upload, SLA messaging.
| 14.2 Dispute Workflow | `issue_service*`, `admin_service`, `notification_service` | State machine, prompts, support dashboard.
| 14.3 Refund Execution | `payment_service`, `issue_service*`, Stripe | Refund API calls, ledger adjustments, notifications.

### Epic 15 — Admin Moderation Toolkit
| Story | Components | Notes |
| --- | --- | --- |
| 15.1 Admin Dashboard & Search | `admin_service*`, admin web app/client, security policies | SSO with MFA, search filters, audit logging.
| 15.2 Takedown & Enforcement | `admin_service*`, `story_service`, `notification_service` | Policy enforcement actions, appeals, evidence storage.
| 15.3 Policy Settings & Templates | `admin_service*`, config store, `notification_service` | Editable thresholds, template previews, change history.

### Epic 16 — Security & Policy Compliance
| Story | Components | Notes |
| --- | --- | --- |
| 16.1 Secrets Rotation & RBAC Audits | `security_service*`, secrets manager, CI | Rotation reminders, RBAC reports, dependency scanning.
| 16.2 Pen-Test Tracking & App Store Policies | `security_service*`, `admin_service`, compliance dashboard | Pen-test registry, policy checklist, status metrics.
| 16.3 Data Subject Requests | `security_service*`, `profile_service`, `order_service` | DSAR intake, export/delete automation, audit logs.

### Epic 17 — Analytics & KPI Reporting
| Story | Components | Notes |
| --- | --- | --- |
| 17.1 Event Schema & Instrumentation | `analytics*`, `analytics_service`, developer tooling | Schema dictionary, unit tests, staging QA checklist.
| 17.2 KPI Pipeline & Dashboards | `analytics_service*`, ETL jobs, BI tool | POAL/offers/bids/payment metrics, trend dashboards, SLA alerts.
| 17.3 Reporting & Exports | `analytics_service*`, scheduler, email service | Weekly digest, CSV/Parquet exports, freshness indicators.

## Usage Guidelines
1. Reference this mapping when creating stories/branches: ensure each PR touches only the components listed for its scope.
2. When introducing new dependencies or services, append them here and update the PRD if they alter assumptions.
3. Architects and tech leads should keep this document in sync with implementation reality after each epic completes.
