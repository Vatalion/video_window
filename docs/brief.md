# Project Brief: Craft Video Marketplace

Status: Finalized v0.1 (Ready for PM handoff)
Date: 2025-09-26

## Executive Summary
- Product concept: A short-form craft marketplace where makers turn story-rich videos into buyable, one-of-a-kind artifacts.
- Problem: Makers currently juggle DMs, comments, and fragmented platforms to sell creations seen in videos; buyers have no clear path from inspiration to ownership.
- Target market: Independent makers creating story-worthy physical artifacts; early adopters among video-centric creators and their audiences.
- Value proposition: One place for makers to tell an artifact’s story and get paid, connecting viewers to offers/auctions and a simple checkout.

## Problem Statement
- Current state: Discovery happens on feeds (TikTok/IG/YouTube), but selling requires platform-hopping, DMs, and manual negotiation. Auctions don’t fit native socials; links break context.
- Impact: Lost sales, poor buyer experience, maker burnout managing comms, and lack of structured pricing. Buyers can’t bid/offer transparently.
- Why existing solutions fall short: Social commerce lacks auction/offer mechanics tied to maker storytelling; marketplaces lack short-form native content and fluid offer→bid flows.
- Urgency: The short-form wave continues; makers seek direct monetization and control. A focused MVP can validate conversion and unit economics.

## Proposed Solution
- Approach: A TikTok-style feed that links to a Story page where an artifact’s narrative lives. Viewers can make offers; the first qualified offer (≥ maker minimum) opens a fixed 72h auction. Makers can accept the current high bid at any time, which ends the auction. Accepted sales move into a 24h payment window, followed by shipping and completion. Auctions use a 15‑minute soft close (bids in final 15 minutes extend by 15, capped at +24h).
- Differentiators: Story-first artifact pages; clean separation of discovery (no prices in feed) vs. transaction in Story; soft-close auction tuned for crafts; maker-controlled auto-reject thresholds; lightweight maker dashboard.
- Why it wins: Aligns with natural maker content, reduces friction from interest to purchase, and supports fair pricing via transparent bidding.
- Vision: Become the default place to turn story-rich craft videos into owned artifacts, expanding into categories, richer creator tools, and community features.

## Target Users
### Primary User Segment: Independent Makers (Creators)
**ICP**: Makers aged 25-45 producing unique physical artifacts (ceramics, jewelry, custom art, handcrafted goods) with strong narrative potential, earning $1K-$10K/month from existing channels, having 10K-100K social media followers. Needs: simple listing and storytelling, fair pricing, minimal back-and-forth, reliable payouts, inventory management.

### Secondary User Segment: Viewers/Buyers of Maker Content
**ICP**: Art collectors and craft enthusiasts aged 28-55, income $60K+, active on social platforms, purchase art/crafts 2-5x annually, value authenticity and maker stories. Wants: clear, trustworthy path to express intent, bid, and pay with predictable shipping and issue handling.

## Goals & Success Metrics
### North Star Metric
- North Star: Paid Orders per Active Listing (POAL) per week during MVP pilot.

### Business Objectives (SMART)
- POAL: ≥ 0.8 average paid orders per active listing per week by pilot week 6.
- Intent rate: ≥ 3% of Story viewers open the Offer/Bid UI within 24h of viewing during MVP.
- Unit economics: Non‑negative contribution margin per paid order (after fees/shipping assumptions) by Cohort M2, measured weekly.
- Supply density: ≥ 100 active listings and ≥ 20 concurrent auctions by end of pilot.

### User Success Metrics (SMART)
- Accept→Pay latency: p50 ≤ 2 hours, p90 ≤ 12 hours within the 24h payment window.
- Checkout success: ≥ 85% from Review to Pay for eligible buyers in the same session or within 24h.
- Ship SLA: ≥ 90% of paid orders have tracking added within 72h of payment.

### KPIs & Definitions
- Offer→Auction rate: % of first non‑rejected offers that open an auction (denominator = listings that received ≥1 offer).
- Soft‑close conversions: % of auctions with any bid placed in the final 1h that triggers an extension.
- Payment within 24h: % of accepts that convert to payment within 24h of acceptance.
- Clean completion rate: % of orders auto/completed without issue opened within 48h of delivery.

### Measurement Notes
- Attribution window: 24h after Story view for intent; session stitched by user/device.
- Instrumentation: track events feed_view, story_view, offer_open, bid_place, offer_accept, payment_success, tracking_added, delivered, issue_opened.
- Reporting cadence: weekly dashboard with cohort breakdowns.

## MVP Scope
### Core Features (Must Have)
- Story listing: Overview (required); Process, Materials/Tools, Notes, Location (optional). “I want this” CTA.
- Minimal in-app capture/composer: Creator records with the device camera inside our app or uploads raw clips from the device; trim/merge and basic captions to compose a short feed video. No external editors or external hardware ingest in MVP; all creation happens in our app.
- Clip Creator: In-app timeline to stitch and trim in-app clips; drag-to-reorder; choose Local (offline) or Server processing. See Technical Considerations → Clip Creator (MVP).
- Offers/Auction mechanics: first qualified offer (≥ maker minimum) opens a 72h auction; 15‑minute soft close (extends by 15 on late bids, max +24h); min next bid = max(1%, 5 units); maker can accept the current high bid anytime to end the auction.
- Payments/Checkout: via Stripe Checkout (hosted) with a 24h payment window; collect shipping address at payment; show fees/tax lines; webhook-driven state; retry/cancel on timeout.
- Orders & Shipping: tracking capture; ship‑by 72h; delivered→auto‑complete 7d; issues window 48h.
- Maker Dashboard: offers queue, active auctions, to-ship list, offer auto‑reject policy.
- Social login: Sign in with Apple and Google; minimal profile + email (consent); link to existing accounts.
- Analytics: event set across feed→story→offer→bid→accept→pay→ship.

### Out of Scope for MVP
- External NLE/editor workflows, third-party ingest hardware, and advanced timeline editing; comments and real-time chat; integrated shipping label purchase; push notifications delivery (prefs only); saved payment methods; offline downloads/playback; robust search.

### MVP Success Criteria
A cohort of listings converts from Story views to offers, auctions, and paid orders with SLA adherence (72h ship, 48h issues), demonstrating viable conversion and operational feasibility.

## Auction Rules (MVP)
- Auction start: First qualified offer (≥ maker‑set minimum) opens a base 48h auction (with popularity tiers 48/72/96h).
- Bidding: Visible current high bid; min next bid = max(1% of current, 5 currency units).
- Soft close: Any bid in the final 15m extends the end time by 15m; total extensions capped at +24h; total auction cap is 7 days.
- Maker accept: Maker may accept the current high bid at any time; acceptance ends the auction and triggers a 24h payment window for the winner.
- Payment: Winner has 24h to pay; on timeout, maker may accept the next highest bid or relist.
- Auto‑reject policy: Maker can set an auto‑reject threshold below which offers do not open an auction.

## Payments & PSP (MVP)
- PSP: Stripe Connect Express — strong Flutter/web SDKs, Apple/Google Pay, onboarding and payouts, Radar, disputes.
- Launch geos: Worldwide; multi-currency support with dynamic currency conversion. Sellers/makers are responsible for all shipping operations including international customs documentation and delivery logistics.
- Methods: Cards (Visa/Mastercard/AmEx) plus Apple Pay and Google Pay; no BNPL/ACH in MVP.
- Checkout: Hosted Stripe Checkout opened in in-app webview; collects shipping address; success/cancel deep links back to app. 3DS/SCA handled by Stripe; PCI scope SAQ A.
- 24h window: Create Checkout Session with expires_at = now + 24h; on timeout cancel the underlying PaymentIntent and return order to offers queue. Allow one retry by regenerating a session within the window.
- Server endpoints: Create Checkout Session; verify and persist on webhooks (checkout.session.completed, payment_intent.succeeded/failed, charge.dispute.created). Drive state machine transitions.
- Payouts: Makers onboard via Connect Express; hold funds in platform balance until delivery + 48h issues window, then transfer to maker. If no tracking after 7d, allow manual review or delayed transfer.
- Fees: Use application_fee_amount; marketplace fee structure: 5% commission on successful sales, minimum $0.50, maximum $50 per transaction; reconcile with per-order metadata (listing_id, maker_id, buyer_id, order_id).
- Refunds/disputes: Manual (admin) in MVP; rely on Stripe Radar defaults; enforce 3DS on elevated risk.
- Compliance: No PAN passes through app/backend; domain verification for Apple/Google Pay handled in Stripe; display privacy policy and TOS links in Checkout.

## Post-MVP Vision
### Phase 2 Features
- Saved cards/wallets; push notifications; label purchase integration; moderation and trust signals; richer search and discovery.

### Long-term Vision
- Creator tools for multi-episode stories, drops, and series; marketplace reputation; category expansion; internationalization and multi-currency/tax support.

### Expansion Opportunities
- Collaborations and charity auctions; secondary resale; brand partnerships for materials/tools.

## Technical Considerations
### Platform Requirements
- Target Platforms: iOS, Android, Web (Flutter)
- Browser/OS Support: Latest iOS/Android; evergreen desktop browsers for web
- Performance Requirements: Smooth video playback in feed; responsive Story and checkout; timers reliable across app states

### Technology Preferences
- Frontend: Flutter app with modular features
- Backend: Dart + Serverpod. MVP as a modular monolith (bounded modules: identity/auth, content/story, listings, offers/auction, payments, orders). Background tasks for timers (soft-close, 24h payments) via Serverpod scheduling/workers. Event-driven transitions with an outbox pattern; evaluate microservices post‑MVP if needed.
- Database: Relational core (offers/bids/orders) with event log; blob store for media
- Hosting/Infrastructure: Managed cloud with serverless timers/schedulers for soft-close and payment windows

### Playback & Player (MVP)
- Streaming: HLS ABR (H.264/AAC), no progressive MP4 and no offline download.
- Auth: Short‑lived, tokenized URLs via CDN or backend; enable CORS and HTTP Range requests.
- Flutter SDKs: `video_player` on iOS/Android (AVPlayer/ExoPlayer); on Web, use `video_player` with an HLS wrapper (hls.js) to support non‑Safari browsers.
- UI controls: Play/Pause, Seek, Mute, Captions toggle; hide download; watermark overlay with viewer id + timestamp; disable casting/AirPlay in MVP.
- Screen capture deterrence: Android `FLAG_SECURE` on playback surfaces; iOS `UIScreen.isCaptured` → blur/pause.
- Subtitles: Optional WebVTT track; show toggle when present.
- Preload: Preroll buffer ≤ 5s; adaptive initial bitrate; autoplay muted in feed allowed; sound requires tap.
- Transcode ladder: H.264 + AAC renditions 240p–1080p; keyframe interval ≈2s; max bitrate 4–6 Mbps.
- Analytics: Emit play, pause, quartiles, completion, errors, buffering; session tied to viewer/device.

### Clip Creator (MVP)
- Purpose: Stitch multiple in‑app clips into one story‑ready short.
- Sources: Only videos captured in this app (no external imports in MVP).
- UI: Bottom horizontal timeline with color‑coded segments; drag‑to‑reorder; trim handles; zoom; live preview above.
- Steps: 1) Add Clips → 2) Choose Processing (Local or Server) → 3) Arrange → 4) Trim → 5) Create Clip → Preview/Export.
- Processing: Local = offline, best for short/simple; Server = needs internet, better for long/complex (status: Uploading → Processing → Ready).
- Troubleshooting: Clips missing? Record in‑app. Timeline stuck? Select segment/Undo. Server issues? Check network or switch to Local.

### Architecture Considerations
- Repository Structure: Flutter app with clean architecture; backend services separated
- Service Architecture: Start as a modular monolith in Serverpod with clear bounded contexts and an event outbox. Split to microservices (offers/auction, payments, orders) only when scaling requires independent deployability or team ownership boundaries.
- Integration Requirements: Stripe Connect (hosted Checkout) for payments; webhooks for payment events; shipping tracking webhook ingestion
- Security/Compliance: No storage of raw PAN; minimal PII in logs; consented analytics

## Constraints & Assumptions
### Constraints
- Budget: MVP lean; prioritize core transaction flows
- Timeline: Pilot in ~8–12 weeks
- Resources: Small full‑stack team; design support part‑time
- Technical: PSP availability and webview SDK constraints; background timers; mobile OS capture/encoding limits for in-app composer; no support for external ingest hardware in MVP.

### Key Assumptions
- Makers can self‑ship reliably; buyers accept 72h ship window
- Soft‑close improves fairness and price discovery
- Enough maker supply to keep auctions active; discovery happens off‑platform initially via shares

## Non-Functional Requirements (NFRs)

### Security & Privacy
- Transport: TLS 1.2+ end-to-end; HSTS enabled on web endpoints.
- At rest: Provider-managed encryption for DB, object storage, and backups.
- Least data: Store only shipping/contact details required for fulfillment; never store PAN.
- Secrets: Managed secret store; rotation ≤ 90 days; no secrets in code or logs.
- AuthZ: Role-scoped access (buyer, maker, admin); server-side checks on all state transitions.
- Webhooks: Verify signatures; process idempotently; respond 2xx within 5s; safe retries.
- Logging hygiene: Redact PII, tokens, and addresses; structured logs only; sampling on noisy paths.

### Content Protection
- Streaming: HLS ABR only (no progressive MP4, no offline) with short‑lived signed URLs (TTL ≤ 5m) for playlists and segments.
- Watermark: Viewer id + timestamp overlay on Story playback; cannot be disabled in MVP.
- Capture deterrence: Android FLAG_SECURE; iOS capture detection -> blur/pause; disable casting/AirPlay.
- CORS/Range: Allow for HLS playback; tokens scoped to path, device/session, and expiration.

### Performance
- App cold start: p50 ≤ 2.5s, p90 ≤ 5.0s on representative mid‑tier devices.
- Feed scroll: 60fps target; jank ≤ 2% on curated device matrix.
- Video start (TTFF): p50 ≤ 1.2s, p90 ≤ 2.0s on Wi‑Fi; rebuffer ratio < 2%.
- Story open to interactive: p50 ≤ 1.0s after navigation.
- Bid/offer UI: optimistic update ≤ 100ms; server round‑trip reflect p95 ≤ 500ms.
- Timers: soft‑close/payment window adjustments applied within 60s of trigger.

### Availability & Reliability
- API availability: ≥ 99.5% monthly during MVP; graceful degradation for non‑critical features.
- Checkout path: ≥ 99.9% leveraging Stripe availability; disable actions when PSP degraded; queue intent where safe.
- Background jobs: At‑least‑once processing with exponential backoff; idempotent state transitions; dead‑letter monitoring.
- Timer guarantees: Schedule/execute within 60s; replay safe; no duplicate side‑effects.

### Observability
- Metrics: RPS, p50/p95 latency, error rates (4xx/5xx) per endpoint, job success/failure, queue depth, timer lag.
- Tracing: Propagate correlation/request id across app→backend→webhooks; sample traces on failures and slow requests.
- Logs: JSON structured; severity set; PII redaction verified in tests.
- Alerting: Error budget burn and SLO breaches (latency/availability) page Sev1 for Checkout/Auction; on‑call runbook links.

### Payments & Compliance
- PCI: SAQ A scope only (hosted Stripe Checkout); no raw PAN through app/backend.
- Idempotency: Use idempotency keys for create/accept/pay; ensure webhook handlers are idempotent and replay‑safe.
- Session window: Checkout Session expires_at = now + 24h; on expiration cancel PaymentIntent; allow one retry within window.
- Risk: Enforce 3DS per Stripe; manual dispute handling in MVP; Radar defaults.

### Accessibility & UX
- Target: WCAG 2.1 AA for web views and Flutter semantics on mobile.
- Controls: Minimum tap target 44×44; proper labels/hints; logical focus order; keyboard navigation on web.
- Captions: WebVTT track supported; captions toggle accessible; respect reduced‑motion settings.
- Contrast: ≥ 4.5:1 for text/icons on web.

### Mobile/Web Constraints
- Background: Pause playback on background; server controls timers; resume safely.
- Offline: Not supported in MVP; show explicit messaging; cache only lightweight thumbnails.
- Webview: Deep link return restores app context; handle 3DS/redirect flows robustly.

### Data Management
- Retention: Logs ≤ 30 days; analytics events ≤ 13 months; transactional (offers/bids/orders) ≥ 24 months (or longer per accounting/legal).
- Backups: Automated daily with PITR; RPO ≤ 15m; RTO ≤ 4h; periodic restore drills.
- Export/Deletion: Support user data export on request and deletion where applicable within 30 days; audit trail retained where required.

### Ops & DR
- Incident response: Sev1 (checkout/auction) acknowledge ≤ 15m, mitigation plan ≤ 60m; status comms template ready.
- Runbooks: Webhook backlog recovery, timer lag, PSP outage toggles, hotfix checklist.
- Infrastructure: IaC for reproducible environments; single‑region MVP with documented failover plan; DR RPO ≤ 15m, RTO ≤ 4h.

## Risks & Open Questions
### Key Risks
- Supply acquisition may lag; auctions without competition reduce excitement
- PSP or tracking integrations may delay timelines
- Abuse/fraud vectors (chargebacks, shill bidding) need early safeguards

### Risk Mitigations
| Risk | Mitigation Action | Owner | Target Date |
| --- | --- | --- | --- |
| Maker supply may lag and auctions lack competition | Seed 30-maker beta cohort with scheduled drops, featured feed placement, and referral bonuses to ensure ≥20 concurrent auctions during pilot | Growth Lead | 2025-10-03 |
| PSP or tracking integrations slip | Timebox Stripe Connect + hosted Checkout webhook spike and document manual tracking fallback flow; flag blockers weekly in standup | Payments Engineer | 2025-10-07 |
| Fraud/abuse surfaces (chargebacks, shill bidding) | Enforce 3DS on all payments, enable Stripe Radar high-risk rules, and stand up manual dispute review SOP before go-live | Trust & Safety Liaison | 2025-10-14 |

### Open Questions
- Geo expansion: when to add CA/EU and alt methods (ACH, BNPL)?
- What qualifies popularity tiers (48/72/96h) algorithmically at launch?
- How to handle multi-item listings (out of scope now) without boxing in future design?

### Areas Needing Further Research
- Fraud prevention baseline and dispute flows
- International shipping/address validation requirements
- Tax handling and fee structure for different geos

## Glossary
- Story: The artifact’s narrative page and associated feed clip(s).
- Listing: A unique artifact available for sale/auction.
- Offer: First price proposal by a buyer; qualified if ≥ maker minimum.
- Bid: Subsequent price increases during an auction.
- Auction: 72h window opened by first qualified offer; 15m soft‑close extensions.
- Accept: Maker action to accept current high bid; starts 24h payment window.
- Winner: Highest bidder at accept or at auction end.
- Payment Window: 24h period for the winner to complete checkout.
- Order: Record created after payment; To Ship → Shipped → Delivered → Completed/Issue.
- Auto‑reject Threshold: Maker minimum below which offers don’t open an auction.
- POAL: Paid Orders per Active Listing (North Star metric).
- HLS ABR: Adaptive streaming format used for playback.
- Stripe Checkout / Connect Express: Hosted payment flow and maker payouts.
- 3DS (3-D Secure): Extra authentication step for card payments triggered via Stripe to reduce fraud.
- PSP (Payment Service Provider): Platform that handles payment processing and payouts (Stripe Connect for MVP).
- Payment Intent: Stripe object representing a single checkout attempt, driving the 24h payment window state machine.
- Hosted Checkout: Stripe-hosted payment page that collects payment method and shipping details securely off-device.
- Serverpod / Outbox: Dart backend framework and reliable event delivery pattern.
- Tokenized URL: Short-lived, signed playback URL that authorizes streaming.
- Soft close: Extension of auction end time when a late bid arrives.
- Viewer watermark: On-screen overlay with viewer id + timestamp to deter leaks.
- In-app composer: Minimal tool to record/upload, trim/merge clips, and caption.
- Ship-by SLA: 72-hour window for makers to add tracking after payment before orders are flagged.
- Tracking number: Carrier-provided identifier used to surface shipment status and close out delivery.

## Appendices
### References
- Wireframes: feed/story, checkout/payment, orders/tracking, maker dashboard
- ACs: MVP Acceptance Criteria document
- Architecture: Offers→Auction→Orders model
- Analytics: MVP event mapping

## Next Steps
### Immediate Actions
1. Implement Stripe Connect + hosted Checkout and webhooks; configure payout policy and test flows — Owner: Payments Eng (Backend/Mobile); Target: 2025-10-17.
2. Stand up Serverpod backend (modules: identity, content/story, listings, offers/auction, payments, orders); set up database schema and event outbox; add schedulers for timers — Owner: Backend Lead; Target: 2025-10-10.
3. Build Story page and Offer/Bid UI per wireframes and ACs — Owner: Mobile Lead (Flutter); Target: 2025-10-24.
4. Implement Checkout stepper with address, payment, review, done; enforce 24h window — Owner: Mobile Lead (Flutter) + Payments Eng; Target: 2025-10-31.
5. Build Orders: To Ship, Add Tracking, Order Detail with timelines — Owner: Mobile Lead (Flutter); Target: 2025-11-07.
6. Instrument analytics events end-to-end; validate against AC mappings — Owner: Analytics Eng; Target: 2025-11-07.

### PM Handoff
This Project Brief provides the full context for Craft Video Marketplace. Please start in 'PRD Generation Mode', review the brief thoroughly, and work with the team to create the PRD section by section, asking for any necessary clarification or suggesting improvements.
