# Craft Video Marketplace Product Requirements Document (PRD)

## Document Status & Epic Alignment

**Document Version:** v0.5  
**Status:** ✅ **APPROVED BY TEAM**  
**Last Updated:** 2025-10-30  
**Approved By:** John (PM), Winston (Architect), Amelia (Dev Lead), Murat (Test Lead), Bob (SM)  
**Approval Date:** 2025-10-30  
**Next Review:** Upon completion of Epic 8 & 13 story development

**⚠️ CRITICAL MVP BLOCKERS:**
- **Epic 8** (Story Publishing): No stories defined - Required for content publishing flow
- **Epic 13** (Shipping & Tracking): No stories defined - Required for order fulfillment

**Current Epic Status:** 11 of 13 MVP epics have complete stories (84.6% story coverage)  
**Technical Validation:** Epic 12 (Payments) approved - 12 remaining epics pending validation  
**Business Approval:** All epics pending stakeholder sign-off per [epic-validation-backlog.md](process/epic-validation-backlog.md)

### Required Approvals Process
Epic validation and stakeholder approvals follow the workflow defined in [story-approval-workflow.md](process/story-approval-workflow.md):

1. **Technical Validation** - Epic tech specs and stories reviewed by technical team
2. **Business Approval** - Product Owner, Executive Sponsor, Legal/Compliance sign-off
3. **Development Authorization** - Both validations complete before implementation begins

**Approval Timeline:** Foundation Epics (01, 1, 4) → Core Features (2, 7, 5) → Commerce (9, 10, 12) → Content (6, 8, 13)

---

## Goals and Background Context

### Goals
- Deliver a single flow from story-rich video discovery to paid order, minimizing maker/buyer friction.
- Validate transparent offer->auction mechanics that sustain >=20 concurrent auctions during pilot.
- Ensure payments, shipping, and order tracking run reliably within defined SLAs.
- Capture actionable analytics (POAL, intent, completion) to guide post-MVP iteration.
- Protect maker content and trust via watermarking, secure streaming, and fraud safeguards.

### Background Context
The marketplace targets independent makers struggling to convert social video interest into purchases. Today they juggle DMs, fragmented tooling, and brittle pricing conversations, leaving buyers unsure how to act. The MVP stitches a TikTok-style feed to narrative "Story" pages where offers trigger structured auctions, backed by Stripe-hosted checkout, self-managed shipping, and analytics.

By pairing in-app creation tools with transparent bidding and strong content protection, the product aims to validate monetization and operational viability before expanding to broader audiences, richer creator tooling, or new geographies.

### Change Log
| Date       | Version | Description                           | Author |
| ---------- | ------- | ------------------------------------- | ------ |
| 2025-09-27 | v0.1    | Initial PRD draft scaffold from brief | PM     |
| 2025-09-30 | v0.2    | Expanded epic stories, architecture alignment, and UX/Dev handoff updates | PM     |
| 2025-10-28 | v0.3    | MVP scope alignment (email-only auth, simplified maker access, DRM deferral) | Product Team |
| 2025-10-30 | v0.4    | Epic status alignment, critical MVP gap identification, updated approval process references | Documentation Team |

## Requirements

### Functional Requirements
- FR1: Present a TikTok-style feed of maker-created shorts with a persistent "View Story" entry point that suppresses price/auction details in-feed.
- FR2: Provide Story pages with video carousel (3-7 clips with dot navigation), Overview, optional Process Timeline (vertical-scroll development journal with sketches/photos/thoughts), Materials/Tools, Notes, and Location sections, anchored by an "I want this" CTA that opens the offer/bid flow.
- FR3: Enable makers to create listings via the in-app composer, recording/importing app-captured clips, creating multiple videos for carousel, stitching, trimming, captioning, and publishing to the feed/Story.
- FR4: Open a 72-hour auction automatically when the first qualified offer (>= maker minimum) is submitted, applying 15-minute soft-close extensions up to +24h.
- FR5: Allow makers to accept the current high bid at any time, immediately transitioning the listing into a 24-hour payment window for the winning buyer.
- FR6: Process payments through Stripe-hosted Checkout that collects shipping details, enforces 24-hour payment window expirations, and supports up to 3 retry attempts with exponential backoff.
- FR7: Manage orders through To Ship -> Shipped -> Delivered -> Completed/Issue states, requiring tracking within 72 hours and auto-completing 7 days post-delivery absent disputes.
- FR8: Surface maker dashboards summarizing active listings, auctions, offers, payments, and fulfillment tasks with real-time status updates and SLAs.
- FR9: Instrument analytics events (feed_view, story_view, offer_open, bid_place, offer_accept, payment_success, tracking_added, delivered, issue_opened) to feed weekly KPI reporting.

### Non-Functional Requirements
- NFR1: Enforce TLS 1.2+, provider-managed encryption at rest, least-data collection, and role-scoped authorization; keep secrets in managed stores with <=90-day rotation.
- NFR2: Serve HLS ABR streams with short-lived signed URLs, viewer watermark overlays, capture deterrence (FLAG_SECURE / capture detection), and no offline or casting support.
- NFR3: Meet performance targets--app cold start p50 <=2.5s/p90 <=5s, TTFF p50 <=1.2s, feed scroll at 60fps with <=2% jank, offer UI optimistic updates <=100ms, timers applied <=60s.
- NFR4: Maintain availability targets--API >=99.5% monthly, checkout path >=99.9%, background jobs idempotent with exponential backoff and dead-letter monitoring.
- NFR5: Provide observability via structured JSON logs, p50/p95 latency and error metrics, distributed tracing across app->backend->webhooks, and SLO-driven alerting.
- NFR6: Limit PCI scope to SAQ A using Stripe Connect Express; apply idempotency keys, enforce 3DS, handle webhook retries safely, and expire checkout sessions at 24h.
- NFR7: Achieve WCAG 2.1 AA accessibility (44x44 targets, semantic labels, focus order, keyboard navigation, captions respecting reduced-motion settings, contrast >=4.5:1).
- NFR8: Adhere to data retention/backups (logs <=30d, analytics <=13m, transactional >=24m), support export/deletion within 30d, and maintain PITR RPO <=15m/RTO <=4h with restore drills.
- NFR9: Prepare ops/DR playbooks covering incident response (Sev1 acknowledge <=15m), webhook backlog recovery, PSP outage toggles, and IaC-managed single-region deployments with failover plan.

## User Interface Design Goals

### Overall UX Vision
Make artifact storytelling the hero: a swipeable short-form feed that invites curiosity, with Story pages unfolding the narrative through structured sections and a prominent "I want this" action. The flow should feel cinematic yet purposeful--each interaction nudging buyers toward intent while keeping makers in control.

### Key Interaction Paradigms
- Vertical, auto-playing feed with lightweight reactions and a fixed "View Story" affordance.
- Story page that progresses from overview to deeper sections, exposing the offer/bid call-to-action without clutter.
- Modal/stepper offer flow that handles qualification, auction state, and confirmation with clear timers.
- Post-accept payment window UI showing countdown, Stripe-hosted checkout entry, and status updates.
- Maker dashboard cards highlighting listing state, auctions in flight, and fulfillment tasks.

### Core Screens and Views
1. Feed (short-form video list)
2. Story detail (narrative sections + CTA)
3. Offer/Bid flow (qualification, bidding, confirmation)
4. Payment window & checkout launcher
5. Orders & tracking management (buyer and maker views)
6. Maker dashboard overview with actionable tiles

### Accessibility: WCAG AA
Commit to WCAG 2.1 AA semantics, captions, contrast, and reduced-motion respect across all screens, ensuring parity for web-rendered flows like Stripe Checkout.

### Branding
No formal brand system yet; assume a clean, craft-forward palette (neutral backdrops, high-contrast typography) with subtle motion that echoes handmade processes. Flag that final color/type tokens will come from design once identity work lands.

### Target Device and Platforms: Mobile Only
Primary experience ships as Flutter mobile (iOS/Android) with embedded webviews for Stripe Checkout; desktop/web responsive variants fall outside MVP scope.

## Technical Assumptions

### Repository Structure: Monorepo
Keep Flutter client, shared domain models, and Serverpod backend co-located so schema/codegen stay in sync and CI can gate the full stack together.

### Service Architecture
Adopt Serverpod 2.9.x as a modular monolith: bounded contexts (identity, content/story, listings, offers/auction, payments, orders) in one deployable, Postgres-backed service with built-in schedulers for auction/payment timers. This honors the brief's guidance to remain monolithic for MVP while leaving room to split later.

### Testing Requirements
Full testing pyramid: Dart unit tests for domain/UI layers, integration tests for offer->auction/payment flows (Serverpod endpoints plus Stripe webhook simulation), and targeted end-to-end Flutter/back-end smoke runs before releases. Manual QA checklists persist for auction/payment edge cases, but automation covers regressions.

### Additional Technical Assumptions and Requests
- Flutter 3.19.6 (Dart 3.5.6) targeting iOS/Android; platform channels only when needed (for example, secure capture hooks).
- Serverpod 2.9.x with Postgres 15, Redis (or Serverpod task queue) for schedulers, and an outbox pattern for webhook/event fan-out.
- Capture pipeline encrypts recorded clips at rest and stores them in managed object storage; playback uses signed HLS manifests with watermark overlays and per-session keys bound to the app platform so only authorized sessions can stream it; maker UI never exposes raw downloads/exports and viewers experience transparent playback in-app.
- Playback relies on short-lived signed URLs and DRM-style protections; chunk-level buffering can be cached ephemerally for smooth playback, but no persistent offline downloads (thumbnails may cache locally).
- Stripe Connect Express with hosted Checkout handles payments/payouts; rely on Stripe webhooks and Radar for payment lifecycle and fraud controls.
- Analytics events flow into a shared collector (for example, BigQuery or Amplitude) via batch export, with common schemas across client and server.
- Deploy single-region (us-east) via IaC (Terraform or similar) with CI/CD gating on Flutter and Serverpod format/analyze/test.
- Feature flags (LaunchDarkly or simple config toggles) manage maker onboarding and auction rule experiments without redeploys.
- Secure content capture on device: Android FLAG_SECURE, iOS screen-capture detection, watermark enforcement, and no OS share/export surfaces.
- Timer and payment enforcement jobs run inside Serverpod with at-least-once semantics; state transitions are idempotent to absorb retries.

## Epic List

### Foundational Epics
1. **Epic 01: Environment & CI/CD Enablement** – Initialize repo structure, branching policy, automated format/analyze/test gates, secrets management, and release channels so the team can ship safely from day one.
2. **Epic 02: Core Platform Services** – Stand up shared design tokens, navigation shell, configuration/feature-flag framework, localization hooks, and telemetry scaffolding to support future features consistently.
3. **Epic 03: Observability & Compliance Baseline** – Implement logging, metrics, alerting hooks, privacy/legal disclosures, and data retention controls so the platform meets governance guardrails prior to feature launch.

### Feature Epics
1. **Epic 1: Viewer Authentication & Session Handling** – Email OTP and social sign-in (Apple, Google), session refresh, secure storage, logout, and account recovery for viewers.
2. **Epic 2: Maker Authentication & Access Control** – Unified authentication (same as viewers), maker profile setup, and basic role flag (simplified RBAC for MVP).
3. **Epic 3: Profile & Settings Management** – Viewer and maker profile editing, avatar/media updates, notification preferences, and legal/consent acknowledgements.
4. **Epic 4: Feed Browsing Experience** – Home feed rendering, pagination, reactions, follow/wishlist hooks, and crash-safe resume.
5. **Epic 5: Story Detail Playback & Consumption** – Story page layout with video carousel (3-7 clips), Process Timeline (development journal), video playback controls, section navigation, accessibility affordances, and share entry points.
6. **Epic 6: Media Pipeline & Content Protection** – Backend ingestion, transcoding to HLS, watermarking, signed URLs (DRM deferred to post-MVP), storage lifecycle, and CDN delivery controls.
7. **Epic 7: Maker Story Capture & Editing Tools** – Capture/import pipeline for multiple clips, carousel creation, clip trimming, ordering, captioning, Process Timeline journaling, and draft autosave.
8. **Epic 8: Story Publishing & Moderation Pipeline** – Draft review, moderation queue, publishing approvals, scheduling, and rollback/versioning.
9. **Epic 9: Offer Submission Flow** – Qualification checks, minimum offer validation, confirmation UI, and cancellation flows.
10. **Epic 10: Auction Timer & State Management** – 72-hour timer lifecycle, soft-close extensions, state transitions, and audit logging.
11. **Epic 11: Notifications & Activity Surfaces** – Real-time mobile push notifications and in-app notifications for offers, bids, wins, maker alerts, and activity inbox with preference controls.
12. **Epic 12: Checkout & Payment Processing** – Stripe Checkout integration, payment window enforcement, up to 3 retry attempts with exponential backoff, and receipt generation.
13. **Epic 13: Shipping & Tracking Management** – Address collection, tracking updates, SLA timers, and status visibility for buyers/makers.
14. **Epic 14: Issue Resolution & Refund Handling** – Issue reporting, dispute workflow, manual/automatic refund actions, and communication trails.
15. **Epic 15: Admin Moderation Toolkit** – Admin dashboard, takedown actions, user suspension, audit trails, and configurable policies.
16. **Epic 16: Security & Policy Compliance** – Secrets rotation, RBAC audits, penetration test remediation, data-subject request handling, and App Store/Play policy validation.
17. **Epic 17: Analytics & KPI Reporting** – KPI dashboards, data export, event schema governance, and scheduled reporting for stakeholders.


## Epic 01: Environment & CI/CD Enablement

**Goal:** Establish a Flutter + Serverpod workspace with enforced guardrails so every contributor can ship confidently from day one.

### Story 01.1 Bootstrap Repository and Flutter App
As a developer,
I want the repo scaffolded with the Flutter client, Serverpod backend, and shared tooling,
so that the team can run, test, and iterate against a consistent structure.
#### Acceptance Criteria
1. Flutter project lives under `video_window` with a passing widget test and README quick-start commands.
2. Serverpod backend scaffold (or placeholder stub) checked in with health endpoint documented for smoke tests.
3. Root README captures prerequisites, local setup, and links to guardrail docs (`AGENTS.md`, story flow).

### Story 01.2 Enforce Story Branching and Scripts
As a developer,
I want branching policies and scripts codified,
so that contributors follow story-based workflows without manual policing.
#### Acceptance Criteria
1. `scripts/story-flow.sh` (or equivalent) automates branch naming, status updates, and PR linking per `.bmad-core` policy.
2. CONTRIBUTING notes outline Conventional Commit rules and story status expectations.
3. Sample story file updated to reflect workflow, and CI blocks non-conforming branches/commits.

### Story 01.3 Configure CI Format/Analyze/Test Gates
As a release manager,
I want GitHub Actions (or equivalent) running format, analyze, and test on every push,
so that regressions are caught before merging into `develop`.
#### Acceptance Criteria
1. `.github/workflows/flutter-ci.yml` runs `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, and `flutter test --no-pub`.
2. Workflow pins Flutter 3.19.6 / Dart 3.5.6 matching local tooling and caches dependencies for speed.
3. Status checks required on PRs targeting `develop`, with documentation on resolving failures.

### Story 01.4 Harden Secrets Management and Release Channels
As a dev lead,
I want secrets, environment handling, and release channels defined,
so that sensitive data stays protected and releases are predictable.
#### Acceptance Criteria
1. `.env.example` (untracked) and README articulate required `--dart-define` keys and secret storage (CI vault, local `.env`).
2. Release channel strategy documented (story branches → `develop` → `main`), including tagging cadence.
3. Validation ensures CI fails when secrets are accidentally committed (git-secrets or pre-commit hook).

## Epic 02: Core Platform Services

**Goal:** Provide shared app primitives—design system, navigation, configuration, and telemetry—that every feature can rely on.

### Story 02.1 Establish Design Tokens and Theming
As a product designer,
I want baseline typography, color, and spacing tokens available in Flutter,
so that the app presents a cohesive visual language before feature work begins.
#### Acceptance Criteria
1. Define light/dark palettes, typography scales, spacing constants, and export via a central Theme extension.
2. Document token usage in `docs/architecture/coding-standards.md` with examples for widgets.
3. Sample screens (splash, placeholder feed) consume tokens without hard-coded colors.

### Story 02.2 Build Navigation Shell and Route Registry
As a user,
I want consistent navigation scaffolding,
so that I can move between feed, story, dashboard, and settings without dead ends.
#### Acceptance Criteria
1. Implement Navigator 2.0 (or chosen router) with typed routes for core destinations.
2. Provide deeplink handling and guarded routes for maker-only areas.
3. Add instrumentation hook when route changes fire for analytics.

### Story 02.3 Implement Configuration and Feature Flag Service
As a release manager,
I want runtime configuration and kill switches,
so that experiments or risky features can be toggled without redeploying.
#### Acceptance Criteria
1. Create configuration service reading remote JSON (or Serverpod endpoint) with local fallback.
2. Feature flag helper exposes strongly typed toggles with unit tests covering defaults and overrides.
3. Document process for adding new flags and auditing active toggles.

### Story 02.4 Instrument Telemetry Scaffolding
As a data analyst,
I want a unified telemetry pipeline,
so that analytics events flow consistently across app and backend.
#### Acceptance Criteria
1. Client SDK wrapper normalizes event names, properties, and user identifiers before dispatching.
2. Serverpod emits structured logs/events aligned with the same schema.
3. Telemetry integration documented with sample event table referencing `docs/analytics/mvp-analytics-events.md`.

## Epic 03: Observability & Compliance Baseline

**Goal:** Ensure the platform is monitorable, legally compliant, and resilient before inviting real users.

### Story 03.1 Implement Structured Logging and Metrics
As an SRE,
I want structured logs and key metrics from day one,
so that issues can be detected and triaged quickly.
#### Acceptance Criteria
1. Flutter app logs user/session identifiers (hashed) with severity levels routed to console → backend collector.
2. Serverpod emits JSON logs with request IDs, latency, and error codes; metrics exported via Prometheus/OpenTelemetry.
3. Dashboard stub (Grafana or similar) documents expected charts and alert thresholds.

### Story 03.2 Stand Up Privacy and Legal Disclosures
As a compliance officer,
I want privacy/legal messaging surfaced clearly,
so that we meet policy obligations before launch.
#### Acceptance Criteria
1. Draft privacy policy, terms, and content guidelines accessible from settings and onboarding.
2. Capture explicit consent for data collection and communications, persisted in the user profile.
3. Document handling for DMCA/takedown requests and link to issue escalation runbook.

### Story 03.3 Define Data Retention and Backup Procedures
As an operations lead,
I want retention, backup, and recovery processes in place,
so that data loss risks are mitigated and compliance targets are met.
#### Acceptance Criteria
1. Configure database backup schedule (daily full, PITR <=15m) with verification steps noted.
2. Object storage lifecycle rules enforce log retention <=30d and analytics <=13m per NFRs.
3. Disaster recovery playbook covers restore testing cadence and escalation contacts.

## Epic 1: Viewer Authentication & Session Handling

**Goal:** Let viewers sign up, sign in, and maintain secure sessions across devices without friction.

### Story 1.1 Implement Email OTP Sign-In
As a viewer or maker,
I want to sign in with email one-time passwords,
so that I can access the marketplace without needing a password.
#### Acceptance Criteria
1. OTP-based email flow with multi-layer rate limiting, account lockout, and comprehensive success/failure messaging.
2. Secure token storage using enhanced Flutter secure storage with AES-256-GCM encryption, RS256 JWT tokens, 15-minute expiry, and automatic refresh rotation via Serverpod.
3. Integration tests cover happy path, invalid OTP attempts, brute force resistance, and token manipulation scenarios.
4. **SECURITY CRITICAL**: Implement cryptographically secure OTP generation with user-specific salts and 5-minute maximum validity.
5. **SECURITY CRITICAL**: Implement progressive account lockout (5 failed attempts → 30 min → 1 hour → 24 hour locks).
6. **SECURITY CRITICAL**: Implement comprehensive JWT token validation with device binding and token blacklisting.
7. **UNIFIED AUTH**: Same authentication flow serves both viewers and makers, with role differentiation happening after successful sign-in.

### Story 1.2 Add Social Sign-In Options
As a viewer,
I want to authenticate with Apple and Google,
so that I can use existing accounts seamlessly.
#### Acceptance Criteria
1. Configure Apple Sign-In (iOS) and Google Sign-In (iOS/Android) per platform guidelines.
2. Serverpod reconciles social identities, preventing duplicate viewer accounts.
3. Fallback to email OTP if social auth fails, with analytics capturing drop-off.
4. **UNIFIED AUTH**: Social accounts link to the same user model as email OTP sign-ins, with post-signin role differentiation.

### Story 1.3 Provide Session Persistence and Logout
As a viewer,
I want my session to persist but be easily revocable,
so that I stay signed in securely across app launches.
#### Acceptance Criteria
1. Session refresh endpoint renews tokens before expiration and handles revocation.
2. Logout clears tokens, wipes cached PII, and sends revoke event to backend.
3. Account recovery flow triggers email verification to reset sign-in method.

## Epic 2: Maker Authentication & Access Control

**Goal:** Let authenticated users complete maker profile setup and gain publishing tools via a unified flow that uses a simple `is_maker` flag (complex RBAC postponed post-MVP).

### Story 2.1 Maker Profile Setup & Review
As an authenticated user who wants to become a maker,
I want to complete a guided profile setup after signing in,
so that I can request maker access without a separate invitation system.
#### Acceptance Criteria
1. Maker profile setup wizard accessible from user settings after unified authentication, guiding business information entry.
2. Basic maker verification with email confirmation and lightweight profile review (full KYC deferred post-MVP).
3. Simple role flag system distinguishing makers from viewers via an `is_maker` boolean with immediate effect after approval.
4. **SECURITY CRITICAL**: Maker profile data stored with encryption for sensitive business information.
5. **UNIFIED AUTH**: Uses the same authentication system as Story 1.1, with role differentiation happening post-signin through profile setup completion.

### Story 2.2 Enforce Maker Access via `is_maker`
As a maker,
I want access only to maker tooling while viewers stay limited,
so that business operations remain secure.
#### Acceptance Criteria
1. Role claims embed the `is_maker` flag in auth tokens and validate it on each privileged API call.
2. Maker-only routes and UI elements hidden/disabled for non-makers.
3. Audit log records maker approvals/denials and subsequent flag changes.

### Story 2.3 Manage Maker Session Security
As a maker,
I want resilient sessions with device visibility,
so that I can trust the platform with my catalog.
#### Acceptance Criteria
1. Maker sessions display connected devices with ability to revoke remotely.
2. 2FA toggle available (email or authenticator) with fallback codes stored securely.
3. Session timeout policies documented and enforced differently from viewer defaults.

## Epic 3: Profile & Settings Management

**Goal:** Enable viewers and makers to manage identities, preferences, and compliance acknowledgements.

### Story 3.1 Deliver Viewer Profile Editing
As a viewer,
I want to update my display details and preferences,
so that my presence reflects my identity.
#### Acceptance Criteria
1. Profile screen edits avatar, display name, bio with client-side validation and optimistic updates.
2. Changes propagate to feed/story surfaces without full reload.
3. Acceptable use notice displayed on first edit and stored in profile metadata.

### Story 3.2 Provide Maker Profile & Shop Settings
As a maker,
I want to present my brand and fulfillment defaults,
so that buyers trust my listings.
#### Acceptance Criteria
1. Maker settings capture shop name, hero media, city, and shipping defaults.
2. Public story pages surface maker card pulling from these settings.
3. Server validation ensures required tax/compliance fields captured before listing.

### Story 3.3 Manage Notification and Consent Preferences
As a user,
I want to choose which notifications I receive and consent to communications,
so that I stay informed without overload.
#### Acceptance Criteria
1. Notification matrix (push, email, in-app) configurable per event type.
2. Consent toggles persist and sync with messaging provider suppression lists.
3. Legal exports reflect latest consents for compliance audits.

## Epic 4: Feed Browsing Experience

**Goal:** Present a scrollable short-form feed that keeps viewers engaged while nudging them toward Story pages.

### Story 4.1 Implement Feed Query and Initial Render
As a viewer,
I want a performant feed of maker stories,
so that I can discover artifacts quickly.
#### Acceptance Criteria
1. Serverpod endpoint delivers paginated feed with personalization hooks.
2. Flutter list renders autoplaying videos with skeleton loaders and retry states.
3. Prefetch logic ensures next two items ready without stalling.

### Story 4.2 Enhance Feed Playback Controls
As a viewer,
I want intuitive playback cues and controls,
so that I can engage without confusion.
#### Acceptance Criteria
1. Tap-to-pause, mute toggle, and caption toggle accessible with WCAG-compliant targets.
2. Analytics events fire for view start, 50%, 90%, and exit reasons.
3. Battery/data saver mode disables autoplay per user preference.

### Story 4.3 Add Lightweight Engagement Hooks
As a viewer,
I want to react or wishlist items from the feed,
so that I can express interest without leaving the scroll.
#### Acceptance Criteria
1. Reaction buttons and wishlist toggle update state optimistically and sync offline.
2. "View Story" pill remains sticky with haptic feedback on tap.
3. Feed items display minimal metadata (maker, artifact title) without pricing per brief.

## Epic 5: Story Detail Playback & Consumption

**Goal:** Tell the artifact’s full narrative through structured sections and accessible playback, converting intent into offers.

### Story 5.1 Lay Out Story Sections and CTA
As a viewer,
I want to explore the artifact's story,
so that I understand the craft before making an offer.
#### Acceptance Criteria
1. Story page renders Overview, Process, Materials/Tools, Notes, optional Location sections.
2. Primary CTA "I want this" anchored and sticky, respecting reduced motion settings.
3. Section navigation supports swipe and tap with analytics for dwell time.

### Story 5.2 Implement Unified Timeline Carousel Interface
As a viewer,
I want to explore the artifact through a primary timeline carousel interface,
so that I can seamlessly navigate between different video contexts and perspectives.
#### Acceptance Criteria
1. Story page opens with a unified timeline carousel as the primary interface, supporting 3-7 video contexts with dot indicators positioned below.
2. First video in carousel serves as the primary context when story opens, with all other videos accessible through horizontal scrolling or dot navigation.
3. Each video context showcases different aspects: "In Use," "Details," "Making Process," "Environment/Lifestyle," "Variations," or custom contexts defined by the maker.
4. Dot indicators show total video count with current position highlighted, supporting tap-to-jump navigation with smooth snap-to-center scrolling and haptic feedback.
5. Story content sections (Overview, Materials, etc.) dynamically adapt based on selected carousel video, highlighting relevant information for that context.
6. Auto-play functionality for selected carousel video with manual override options and memory persistence for user's preferred viewing context.
7. Contextual deep links allow sharing specific video contexts that open directly to that carousel position.

### Story 5.3 Deliver Accessible Video Playback and Transcripts
As an accessibility-focused viewer,
I want captions and transcript support,
so that I can consume the story regardless of hearing ability.
#### Acceptance Criteria
1. Player exposes captions, playback speed, and scrubbing with accessibility labels for all videos in the timeline carousel.
2. Transcript panel syncs with currently selected carousel video timeline and is downloadable (text only) respecting DRM.
3. Watermark and signed URL protections enforced identically across all videos in the timeline carousel.

### Story 5.4 Provide Share and Save Entry Points
As a viewer,
I want to share or revisit stories,
so that I can spread interest or return later.
#### Acceptance Criteria
1. Share sheet generates deep links with expiration and context (specific timeline video context).
2. Wishlist/save adds to personal collection accessible offline (metadata only) with preferred timeline context remembered.
3. Analytics capture share type, timeline context engagement, and conversion path.

## Epic 6: Media Pipeline & Content Protection

**Goal:** Securely process maker media from upload through protected playback with watermarks and DRM-style safeguards.

### Story 6.1 Build Upload Ingestion Service
As a maker,
I want to upload raw clips reliably,
so that my story assets are safe before editing.
#### Acceptance Criteria
1. Chunked upload API with resumable support and client retries.
2. Virus scanning and basic validation (duration, format) before acceptance.
3. Storage keys namespaced per maker with encryption at rest verified.

### Story 6.2 Transcode to HLS with Watermarking
As a platform engineer,
I want output renditions optimized for playback,
so that viewers receive smooth streams without risking piracy.
#### Acceptance Criteria
1. Transcoding pipeline produces multiple bitrates with consistent watermark overlays including session identifiers.
2. Job status surfaced to maker so they understand processing progress.
3. Failed jobs alert ops and allow retry without duplicating storage.

### Story 6.3 Serve Signed URLs and Playback Policies
As a security lead,
I want strict controls around media access,
so that only authorized viewers can stream.
#### Acceptance Criteria
1. Signed URL service issues short-lived tokens bound to user session/device.
2. Player enforces token refresh and revocation on logout/bid rejection.
3. CDN configuration documented with geo/IP restrictions per compliance needs.

## Epic 7: Maker Story Capture & Editing Tools

**Goal:** Let makers capture, edit, and assemble videos inside the app with confidence their progress is preserved.

### Story 7.1 Enable Capture and Import Pipeline
As a maker,
I want to capture clips or import existing footage,
so that I can assemble stories without leaving the app.
#### Acceptance Criteria
1. In-app camera supports multi-clip capture with exposure/focus controls.
2. Import from gallery enforces supported formats and warns on DRM content.
3. Local encryption stores raw clips until upload completes.

### Story 7.2 Provide Timeline Editing and Captioning
As a maker,
I want to trim, reorder, and caption clips,
so that the narrative feels intentional.
#### Acceptance Criteria
1. Timeline editor allows drag-to-reorder, split/trim, and preview transitions.
2. Caption editor auto-suggests text (optional) and supports manual edits with styling.
3. Autosave after each edit with conflict resolution when switching devices.

### Story 7.3 Create Unified Timeline Carousel
As a maker,
I want to create a single timeline carousel with multiple video contexts,
so that viewers can seamlessly explore my product from different perspectives.
#### Acceptance Criteria
1. Carousel creation interface allows adding 3-7 video clips with context labels (In Use, Details, Making Process, Environment, Variations, or custom labels).
2. First video in carousel sequence becomes the primary context when viewers open the story, but any video can be accessed through dot navigation or horizontal scrolling.
3. Drag-and-drop reordering of carousel videos with visual preview thumbnails and duration indicators, including the ability to set which video appears first.
4. Context assignment tools with predefined categories and custom label creation (up to 30 characters).
5. Auto-preview mode to test carousel flow, dot indicator positioning, and content adaptation before publishing.
6. Performance optimization tools for all carousel videos (compression recommendations, file size limits, format validation).
7. Analytics preview showing expected engagement metrics for different carousel arrangements and first-video selections.

### Story 7.4 Manage Draft Autosave and Sync
As a maker,
I want my drafts preserved across sessions,
so that I never lose progress.
#### Acceptance Criteria
1. Draft state synced to backend with version history and last-updated timestamp, including carousel context configurations.
2. Offline mode queues changes and reconciles once online, highlighting conflicts in timeline carousel structure.
3. Draft dashboard lists in-progress stories with resume actions, showing carousel completion status.

## Epic 8: Story Publishing & Moderation Pipeline

**Goal:** Ensure stories go live safely through moderation while allowing makers to plan releases.

### Story 8.1 Launch Moderation Queue
As a moderation lead,
I want a queue of submitted stories,
so that content quality stays high.
#### Acceptance Criteria
1. Makers submit drafts for review with required checklist confirmations.
2. Moderators view story assets, metadata, and automated flags in one interface.
3. Decisions (approve, reject with feedback) notify makers and log outcomes.

### Story 8.2 Support Publishing Approvals and Scheduling
As a maker,
I want to schedule approved stories,
so that launches align with my marketing.
#### Acceptance Criteria
1. Approved stories can go live immediately or at scheduled time (with timezone handling).
2. Scheduler handles conflicts and alerts makers if prerequisites (inventory, compliance) missing.
3. Publishing status reflected in maker dashboard and feed ingestion pipeline.

### Story 8.3 Provide Versioning and Rollback
As an operations lead,
I want version history for stories,
so that we can revert problematic content quickly.
#### Acceptance Criteria
1. Each publish creates immutable version snapshot with media references.
2. Rollback action restores prior version and documents reason.
3. Audit log tracks who initiated rollbacks and notifications sent to buyers.

## Epic 9: Offer Submission Flow

**Goal:** Capture buyer intent through qualified offers that transition seamlessly into auctions.

### Story 9.1 Build Offer Entry UI and Eligibility Checks
As a buyer,
I want a clear flow to submit an offer,
so that I understand requirements before bidding.
#### Acceptance Criteria
1. Offer modal guides through account verification, payment method placeholder, and policy acknowledgement.
2. Client validates offer meets maker minimum and communicates auction rules.
3. Analytics track abandon points and reasons.

### Story 9.2 Validate Offers Server-Side and Trigger Auctions
As a platform,
I want to validate offers before opening auctions,
so that only qualified bids move forward.
#### Acceptance Criteria
1. Serverpod verifies payment eligibility, maker availability, and duplicate offer conflicts.
2. First accepted offer transitions listing into auction state with timers initialized.
3. Makers receive real-time notification and can accept immediately.

### Story 9.3 Handle Offer Withdrawal and Cancellation
As a buyer,
I want transparency if I need to withdraw before auction,
so that I stay in good standing.
#### Acceptance Criteria
1. Buyers can withdraw offer before acceptance with confirmation and penalty messaging.
2. System logs withdrawal reason and adjusts auction triggers if applicable.
3. Makers see withdrawal history and updated pipeline in dashboard.

## Epic 10: Auction Timer & State Management

**Goal:** Maintain the auction lifecycle with precise timers, soft closes, and auditability.

### Story 10.1 Implement Auction State Machine
As a marketplace operator,
I want a deterministic state machine,
so that auctions transition correctly.
#### Acceptance Criteria
1. States include Listed, Offer Pending, Auction Live, Awaiting Payment, Completed, Cancelled.
2. Serverpod scheduler ticks timers and persists transitions atomically with retries.
3. State transitions emit events for analytics and notifications.

### Story 10.2 Add Soft-Close and Bid Increment Logic
As a bidder,
I want fair soft-close rules,
so that last-second sniping is discouraged.
#### Acceptance Criteria
1. Bid placement within final 15 minutes extends timer per rules (max +24h).
2. Minimum next bid logic `max(current*1.01, +5 units)` enforced server-side.
3. UI displays countdown, extension announcements, and increment guidance.

### Story 10.3 Record Audit Trails and Compliance Logs
As a compliance officer,
I want full traceability of auction activity,
so that disputes can be resolved quickly.
#### Acceptance Criteria
1. Every bid, withdrawal, and state change stored with timestamp, actor, and source IP/device.
2. Export endpoint provides CSV/JSON for audits with filtering.
3. Alerts trigger on suspicious patterns (rapid bids, repeated withdrawals).

## Epic 11: Notifications & Activity Surfaces

**Goal:** Keep users informed about offers, auctions, and fulfillment through timely, actionable messaging.

### Story 11.1 Stand Up Notification Service
As a platform engineer,
I want a unified notification service,
so that mobile push, email, and in-app alerts stay consistent.
#### Acceptance Criteria
1. Notification service abstracts providers (Firebase APNs, email) with templating.
2. Preference checks performed before send, respecting opt-outs.
3. Dead-letter queue captures failed sends with retry policy.

### Story 11.2 Deliver Offer and Auction Notifications
As a buyer,
I want real-time updates on auction changes,
so that I can respond quickly.
#### Acceptance Criteria
1. Buyers receive notifications for offer acceptance, outbid events, soft-close extensions, and payment windows.
2. Makers receive notifications for new offers, bids, and payment completion.
3. Notification copy references countdown timers and CTA deep links.

### Story 11.3 Build Activity Inbox UI
As a user,
I want a consolidated activity feed,
so that I can catch up on marketplace events.
#### Acceptance Criteria
1. In-app inbox lists chronological notifications with filters (offers, auctions, orders).
2. Tapping entries deep links to relevant screens and marks as read.
3. Empty states and badge counts align with design tokens and accessibility guidelines.

## Epic 12: Checkout & Payment Processing

**Goal:** Convert accepted bids into paid orders via Stripe Checkout while enforcing payment windows and reconciliation.

### Story 12.1 Launch Stripe Checkout from Story CTA
As a buyer,
I want to complete payment through a trusted flow,
so that I can finalize my purchase quickly.
#### Acceptance Criteria
1. Stripe Checkout session created with artifact details, maker payout account, and shipping requirement.
2. Buyers redirected to hosted page with analytics event capturing start.
3. Webhook `checkout.session.completed` updates order to Paid and notifies maker.

### Story 12.2 Enforce 24-Hour Payment Window
As a marketplace operator,
I want accepted bids to pay promptly,
so that listings don’t stall.
#### Acceptance Criteria
1. Timer starts on maker acceptance and displays countdown across buyer surfaces.
2. Non-payment triggers session cancellation, notifies maker, and offers next highest bidder.
3. Retrying payment within window issues fresh session and logs attempts.

### Story 12.3 Generate Receipts and Payment Audit Trail
As a finance analyst,
I want reliable records,
so that revenue can be reconciled.
#### Acceptance Criteria
1. Receipts emailed to buyer and maker with order breakdown.
2. Ledger service records gross amount, fees, payouts, and status changes.
3. Failed payments produce actionable error codes and retry guidance.

## Epic 13: Shipping & Tracking Management

**Goal:** Coordinate post-payment fulfillment through address collection, tracking, and SLA-driven reminders.

### Story 13.1 Collect Shipping Details at Checkout
As a buyer,
I want to provide shipping info seamlessly,
so that my order ships to the right place.
#### Acceptance Criteria
1. Stripe Checkout collects address and phone, which sync back to Serverpod.
2. Buyers can edit address until tracking is added.
3. Address validated against postal rules with error feedback.

### Story 13.2 Guide Makers Through Tracking and Shipping Windows
As a maker,
I want reminders to ship on time,
so that I stay compliant with SLAs.
#### Acceptance Criteria
1. Maker dashboard surfaces pending shipments with countdown to 72-hour deadline.
2. Tracking entry form validates carrier/number and updates buyer immediately.
3. Failure to add tracking triggers escalation workflow and support notifications.

### Story 13.3 Provide Order Tracking Visibility for Buyers
As a buyer,
I want to monitor my shipment,
so that I know when to expect delivery.
#### Acceptance Criteria
1. Order detail screen shows tracking status, carrier link, and estimated delivery.
2. Push/email updates fire on shipped, out for delivery, delivered milestones.
3. Auto-complete to Completed occurs 7 days after delivery if no issues opened.

## Epic 14: Issue Resolution & Refund Handling

**Goal:** Offer structured mechanisms for reporting issues, resolving disputes, and executing refunds.

### Story 14.1 Enable Issue Reporting
As a buyer,
I want to flag problems quickly,
so that the marketplace can help resolve them.
#### Acceptance Criteria
1. Issue button active from delivery through 48-hour window with reason codes.
2. Buyers upload evidence (photos/text) securely to dispute record.
3. Confirmation outlines next steps and response SLA.

### Story 14.2 Manage Dispute Workflow
As a support agent,
I want a clear workflow,
so that cases progress efficiently.
#### Acceptance Criteria
1. Dispute states (Open, Under Review, Awaiting Response, Resolved, Escalated) tracked with timestamps.
2. Makers and buyers receive prompts to respond with deadlines.
3. Support dashboard shows queue, severity, and recommended actions.

### Story 14.3 Execute Refunds and Settlement Actions
As a finance analyst,
I want controlled refund handling,
so that payouts adjust correctly.
#### Acceptance Criteria
1. Refund decisions trigger Stripe API calls and update ledger entries.
2. Partial refunds supported with pro-rated marketplace fees.
3. Notifications summarize outcome for both parties and close dispute.

## Epic 15: Admin Moderation Toolkit

**Goal:** Equip internal teams to monitor users, enforce policies, and respond to marketplace risks.

### Story 15.1 Build Admin Dashboard and User Search
As an admin,
I want to locate users and listings quickly,
so that I can intervene when needed.
#### Acceptance Criteria
1. Secure admin portal behind SSO with MFA enforcement.
2. Search filters by user, listing, status, and recent activity.
3. Admin actions logged with reason codes.

### Story 15.2 Provide Listing Takedown and Enforcement Tools
As an admin,
I want to enforce policies,
so that the marketplace stays trusted.
#### Acceptance Criteria
1. Takedown flow removes listings from feed/story and notifies maker with appeal option.
2. Repeat violations trigger automatic cooldown or suspension per policy matrix.
3. Evidence attachments stored securely for compliance review.

### Story 15.3 Configure Policy Settings and Templates
As a policy manager,
I want to update enforcement rules,
so that guidelines adapt without code deploys.
#### Acceptance Criteria
1. Policy config file (or admin UI) manages thresholds (strikes, cooldown durations).
2. Notification templates editable with preview before publishing.
3. Change history maintained with author and timestamp.

## Epic 16: Security & Policy Compliance

**Goal:** Maintain a security posture that satisfies platform policies and prepares for audits.

### Story 16.1 Implement Secrets Rotation and RBAC Auditing
As a security engineer,
I want automated checks on secrets and access,
so that credentials stay hardened.
#### Acceptance Criteria
1. Secrets stored in managed vault with rotation reminders <=90 days.
2. Scripts generate RBAC reports highlighting deviations.
3. CI enforces dependency scanning and fails on leaked secrets.

### Story 16.2 Track Pen-Test Findings and App Store Policies
As a compliance lead,
I want visibility into security posture,
so that remediation stays on track.
#### Acceptance Criteria
1. Register third-party pen-test findings with owner, severity, due date.
2. App Store/Play policy checklist maintained with evidence attachments.
3. Status dashboard indicates open vs closed items and blockers.

### Story 16.3 Handle Data Subject Requests
As a privacy officer,
I want DSAR workflows,
so that user rights are respected.
#### Acceptance Criteria
1. Request intake form and authentication process implemented.
2. Data export/delete automation covers profiles, orders, and media references within SLA.
3. Audit log records request lifecycle and communication history.

## Epic 17: Analytics & KPI Reporting

**Goal:** Deliver actionable insights across the funnel with trustworthy dashboards and exports.

### Story 17.1 Define Event Schema and Instrumentation
As a data engineer,
I want a governed event schema,
so that analytics stay consistent.
#### Acceptance Criteria
1. Event dictionary finalized in `docs/analytics/mvp-analytics-events.md` with owners.
2. Client and server instrumentation emits required payloads with unit tests verifying shapes.
3. QA checklist ensures events fire in staging before release.

### Story 17.2 Build KPI Pipeline and Dashboards
As a product manager,
I want visibility into funnel performance,
so that I can steer the roadmap.
#### Acceptance Criteria
1. ETL jobs aggregate POAL, offers, bids, payment conversion, shipping SLA metrics.
2. Dashboard (Looker, Data Studio, etc.) visualizes weekly trends with filters by cohort.
3. SLA alerts configured for key KPIs dipping below thresholds.

### Story 17.3 Schedule Reporting and Stakeholder Exports
As an executive stakeholder,
I want automated reports,
so that I stay informed without manual pulls.
#### Acceptance Criteria
1. Weekly email digest summarizing KPIs delivered to stakeholder list.
2. CSV/Parquet exports available for ad-hoc analysis with access controls.
3. Data freshness indicators included in dashboards and emails.

## Checklist Results Report

- ✅ Verified Goals & Background align with latest brief v0.1 and call out all MVP guardrails.
- ✅ Functional (FR1–FR9) and Non-Functional (NFR1–NFR9) requirements trace to brief statements with no gaps.
- ✅ UI Design Goals cover vision, interactions, accessibility, branding placeholders, and platform scope.
- ✅ Technical Assumptions reflect monorepo, Serverpod monolith, testing pyramid, and security controls from brief.
- ✅ Epic List approved and expanded into detailed stories with vertical slices and acceptance tests.
- ✅ Story acceptance criteria include critical NFR references (accessibility, timers, security) where applicable.
- ✅ Handoff sections below provide actionable prompts for downstream personas.

## Timeline Carousel Use Cases and Benefits

### Example Use Cases

#### Jewelry Maker
**Timeline Carousel Structure:**
- **Video 1 (Primary) - "In Use":** Model wearing the necklace at a café, showing scale and lifestyle fit
- **Video 2 - "Details":** Macro shots of clasp mechanism, stone setting, and engraving details
- **Video 3 - "Making Process":** Time-lapse of metalworking, stone setting, and final polishing
- **Video 4 - "Variations":** Same design in different metals (silver, gold, rose gold)

#### Ceramic Artist
**Timeline Carousel Structure:**
- **Video 1 (Primary) - "Environment":** Mug displayed in kitchen setting, showing size and functionality
- **Video 2 - "Details":** Close-up of glaze texture, handle ergonomics, and bottom stamping
- **Video 3 - "Making Process":** Wheel throwing footage, glazing technique, and kiln firing
- **Video 4 - "Care Instructions":** Proper washing and maintenance demonstration

#### Woodworker
**Timeline Carousel Structure:**
- **Video 1 (Primary) - "In Use":** Person using the wooden cutting board during food preparation
- **Video 2 - "Craftsmanship":** Joint details, wood grain patterns, and finish close-ups
- **Video 3 - "Materials":** Source wood types, sustainably harvested materials showcase
- **Video 4 - "Customization":** Different sizes, engraving options, and personalization

#### Fashion Designer
**Timeline Carousel Structure:**
- **Video 1 (Primary) - "Runway":** Model walking in different lighting conditions
- **Video 2 - "Details":** Fabric texture, stitching quality, and closure mechanisms
- **Video 3 - "Styling Options":** Different ways to wear/accessorize the garment
- **Video 4 - "Behind the Scenes":** Design process, pattern making, and construction

### Key Benefits

#### For Viewers
1. **Comprehensive Understanding:** Multiple contexts provide complete product awareness before purchase decisions
2. **Trust Building:** Seeing the making process and materials increases confidence in quality
3. **Visualization:** Lifestyle contexts help buyers envision product use in their own lives
4. **Reduced Uncertainty:** Details and variations context answer common questions proactively

#### For Makers
1. **Narrative Control:** Ability to present products in the exact contexts they want customers to understand
2. **Showcase Versatility:** Demonstrate multiple use cases and applications of the same product
3. **Differentiation:** Stand out by providing richer context than competitors
4. **Process Transparency:** Share craftsmanship story that justifies value and pricing

#### For Platform
1. **Higher Engagement:** Users spend more time exploring multi-context stories
2. **Better Conversion Rates:** Comprehensive understanding reduces purchase hesitation
3. **Increased Shareability:** Specific contexts create more shareable content moments
4. **Data Insights:** Analytics reveal which contexts drive most engagement and conversions

### Technical Advantages
1. **Performance Optimized:** Single carousel interface with lazy loading and caching ensures smooth performance
2. **Mobile-Native Interaction:** Unified horizontal scrolling and dot indicators provide intuitive touch navigation
3. **Scalable Architecture:** 3-7 video limit balances rich content with performance constraints
4. **Simplified State Management:** Single carousel component reduces complexity compared to dual-component approach
5. **Consistent UX:** All videos follow the same interaction patterns and accessibility standards
6. **DRM Compliant:** All carousel videos maintain identical security protections

## Next Steps

### UX Expert Prompt
Deliver high-fidelity mockups for primary flows (Feed, Story, Offer/Bid, Payment, Orders, Maker dashboard) by 2025-10-07, including accessibility annotations and component token references. Update `docs/architecture/ux-dev-handoff.md` with final asset links.

### Architect Prompt
Keep `docs/architecture.md` and `docs/architecture/front-end-architecture.md` in sync as UX assets finalize and new technical decisions arise (media pipeline, notification tooling). Document significant updates in the Change Log and notify stakeholders.
