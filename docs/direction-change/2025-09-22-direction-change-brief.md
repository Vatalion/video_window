# Direction Change Brief — 2025-09-22

Status: Draft

Owner: Product Owner (User)
Stakeholders: PO, PM, Engineering, Design, QA, Legal/Compliance
Decision horizon: TBD (suggest within 2 weeks, e.g., 2025-10-06)  
Related docs: [PRD](../prd.md), ADR: TBD

---

## 1) Executive summary (From → To)
- From (current direction, 1–2 sentences): TikTok-like shop experience.
- To (new direction, 1–2 sentences): A service for craftsmen/creators of unique handmade goods or services, enabling viewers to propose a bid directly from short videos and open an auction for the featured item.
- Why now (evidence/insights/constraints/opportunity): Founder intent and product vision; previous team direction misinterpreted the goal—this pivot realigns to the original vision.

Non‑negotiables (guardrails):
- Timeline: No fixed timeline.
- Budget: Unlimited budget for implementation.
- Platform(s): Android, iOS, Web.
- Compliance/Security: TBD (see Security/Compliance notes below).

Key Success Metrics (KPIs) — proposed:
- KPI #1: Bid proposal rate — Baseline: TBD → Target: ≥5% by Sprint N+2; Measurement: bids_proposed / item_video_views (analytics events).
- KPI #2: Creator activation rate — Baseline: TBD → Target: ≥30% by Sprint N+2; Measurement: creators who publish ≥1 short video with item details and open an auction / onboarded creators.
- KPI #3: Auction liquidity — Baseline: TBD → Target: ≥80% of auctions receive ≥2 bids within 24h by Sprint N+2; Measurement: bids per auction distribution.

Decision criteria (go/no‑go):
- Achieve bid proposal rate ≥3% on pilot cohort AND median time-to-first-bid ≤2 minutes, with <1% event error rate and no critical compliance blockers.

---

## 2) Scope of change
- In‑scope (what changes):
	- Buyer: feed with auction indicators; propose bid CTA from video; bid entry/confirmation; item details with bids history.
	- Creator: creator studio (project creation), upload media (photos/videos/thoughts), creation history page, short video composition from uploaded clips, tagging/naming/description, publish to feed with product overlay linking to details.
	- Auctions: create/open auction on bid, accept bids, show real-time updates, basic anti-sniping (optional), timers.
	- Telemetry: core analytics for feed impressions, CTA taps, bids, auction state changes.
- Out‑of‑scope (what stays the same/for later):
	- Direct checkout, payments/escrow/disbursements, shipping/returns.
	- Advanced personalization/recommendations, ad-tech, marketplace fees, ratings/reviews.
	- Full content moderation pipeline (initially minimal/manual; scale later).
- Assumptions:
	- Handmade/unique items; creators own content rights; auctions are for discovery/commitment, with payments added later.
	- Flutter app across Android/iOS/Web using shared codebase.
- Constraints:
	- Real-time signaling for bids/auction state required; choose approach compatible with current stack.
	- Compliance TBD may constrain auction mechanics in certain regions; pilot region gated to Ukraine-only.
	- Auction rule MVP: min bid increment fixed at +1 USD; anti-snipe optional in pilot.
	- Realtime stack MVP: WebSockets; evaluate managed alternatives later.

---

## 3) Impact mapping
Users and journeys impacted:
- Personas/segments: Buyer (viewer/collector), Creator (craftsman/artist), Admin/Moderator.
- Top user journeys affected:
	- Buyer: open app → scroll feed → see video with item overlay → tap "Propose bid" → enter amount → confirm → see success → auction state visible in feed and details → view bids history.
	- Creator: log in → create project → upload media and notes → creation history page auto-builds → compose short video from uploads → add tags/name/description → publish → video appears in feed with overlay → propose bid leads to auction (if ongoing) and bids history visible.

Product/UX:
- Screens/flows to update: feed screen, item overlay, bid modal, confirmation, item details page, bids history, creator studio (project, uploads, composition), publish flow.
- Content/copy: clear CTA for bidding; disclosures that bids open auctions; creator guidance for tagging and presentation.

Technical:
- Architecture/SDKs/APIs: video ingestion and composition tooling; auction service (create auction, place bid, list bids, state transitions); real-time updates (WebSockets/Streams); feature flags.
- Data schema/storage: entities for Creator, Project, Item, MediaAsset, ShortVideo, Auction, Bid; indexes for feed and active auctions.
- Telemetry/analytics events: feed_impression, cta_propose_bid_tap, bid_submitted, bid_confirmed, auction_opened, auction_state_changed, bids_viewed, creator_publish, short_video_composed.
- Infra/DevOps: storage for media; CDN; real-time channel infra; background jobs for auction timers; monitoring and alerts.
- Security/Privacy/Compliance: age-appropriate content, IP/ownership attestations, anti-fraud/shill bidding checks, auction legality by region, ToS disclosures; PII minimal at pilot.

Dependencies:
- Internal (teams/services): core auth, media pipeline, analytics, notifications.
- External (vendors/SDKs/3rd‑party): video processing/FFmpeg, real-time messaging, crash reporting, CDN/storage provider.

---

## 4) Backlog reshape (Keep / Adjust / Drop / New)
Guidance: tag existing stories with one of Keep/Adjust/Drop and list proposed New stories.

| Story/Artifact | Decision | Notes |
| --- | --- | --- |
| docs/stories/01.identity-access/01.01-user-registration.md | Keep | Core access. |
| docs/stories/01.identity-access/01.02-social-login.md | Keep | Lowers friction. |
| docs/stories/01.identity-access/01.05-session-management.md | Keep | Core. |
| docs/stories/01.identity-access/01.07-user-profile.md | Keep | Profiles needed for creators/bidders. |
| docs/stories/01.identity-access/01.03-multi-factor-auth.md | Adjust | Prioritize for creators/high-value bidders. |
| docs/stories/01.identity-access/01.10-merchant-kyc-and-compliance.md | Adjust | Refocus on creator verification/KYC-lite. |
| Proposed: docs/stories/01.identity-access/01.xx-age-gating-and-region-restrictions.md | New | Region gating and age policies for auctions. |
| docs/stories/02.catalog-merchandising/02.03-product-media-management.md | Keep | Essential for creator projects. |
| docs/stories/02.catalog-merchandising/02.01-product-authoring.md | Adjust | Unique Item authoring tied to Project (single-unit). |
| docs/stories/02.catalog-merchandising/02.02-catalog-management.md | Adjust | Projects/Items vs. broad SKUs. |
| docs/stories/02.catalog-merchandising/02.04-inventory-management.md | Adjust | Single-unit availability per item. |
| docs/stories/02.catalog-merchandising/02.05-product-variants.md | Drop (defer) | Not applicable to unique items. |
| Proposed: docs/stories/02.catalog-merchandising/02.xx-project-item-linking.md | New | Project → Item mapping and overlays. |
| docs/stories/03.content-creation-publishing/03.01-video-capture-interface.md | Keep | Input for creator studio. |
| docs/stories/03.content-creation-publishing/03.02-timeline-tools.md | Keep | Useful for composition. |
| docs/stories/03.content-creation-publishing/03.03-media-management-system.md | Keep | Asset pipeline. |
| docs/stories/03.content-creation-publishing/03.07-publishing-workflow.md | Keep | Publish to feed. |
| docs/stories/03.content-creation-publishing/03.08-content-scheduling.md | Adjust | Lower priority; manual in pilot. |
| docs/stories/03.content-creation-publishing/03.99-pilot-creator-studio-mvp.md | New | Project, uploads, short video composition, publish. |
| docs/stories/04.shopping-discovery/04.04-browse-discovery.md | Keep | General discovery. |
| docs/stories/04.shopping-discovery/04.05-category-tagging.md | Keep | Tag-driven discovery. |
| docs/stories/04.shopping-discovery/04.06-content-feed.md | Keep | Add auction indicators via overlay. |
| docs/stories/04.shopping-discovery/04.03-search-functionality.md | Adjust | Add auction filters later. |
| docs/stories/04.shopping-discovery/04.07-personalization-engine.md | Adjust | Minimal ranking for pilot. |
| docs/stories/04.shopping-discovery/04.09-commerce-profile-integration.md | Adjust | Show creator portfolios and active auctions. |
| docs/stories/04.shopping-discovery/04.99-pilot-bid-from-feed.md | New | CTA → amount entry → confirm → success and auction open. |
| docs/stories/04.shopping-discovery/04.98-item-details-with-bids-history.md | New | Details with bids list and state. |
| docs/stories/05.checkout-fulfillment/05.01-multi-step-checkout.md | Drop (defer) | Payments later. |
| docs/stories/05.checkout-fulfillment/05.06-card-payment-processing.md | Drop (defer) | Out of pilot scope. |
| docs/stories/05.checkout-fulfillment/05.07-digital-wallets.md | Drop (defer) | Payments later. |
| docs/stories/05.checkout-fulfillment/05.08-subscription-bnpl.md | Drop (defer) | Not needed for auctions pilot. |
| docs/stories/05.checkout-fulfillment/05.09-refund-cancellation.md | Drop (defer) | Not applicable without payments. |
| docs/stories/06.engagement-retention/06.01-comment-system.md | Keep | Social proof around items. |
| docs/stories/06.engagement-retention/06.02-reaction-system.md | Keep | Lightweight engagement. |
| docs/stories/06.engagement-retention/06.05-notifications-messaging.md | Adjust | Focus on bid/outbid/win in N+1. |
| docs/stories/06.engagement-retention/06.06-moderation-reviews.md | Adjust | Include creator attestations/reporting. |
| docs/stories/06.engagement-retention/06.04-abandoned-cart-recovery.md | Drop (defer) | Not applicable without checkout. |
| Proposed: docs/stories/06.engagement-retention/06.xx-auction-notifications.md | New | Bid placed/outbid/auction ended. |
| Proposed: docs/stories/06.engagement-retention/06.xx-report-content-and-shill-bidding.md | New | Reporting flows for content/bids. |
| docs/stories/07.admin-analytics/07.01-admin-dashboard.md | Keep | Ops visibility. |
| docs/stories/07.admin-analytics/07.02-analytics-platform.md | Keep | Data foundation. |
| docs/stories/07.admin-analytics/07.03-configuration-management.md | Adjust | Feature flags and kill switch for auctions. |
| Proposed: docs/stories/07.admin-analytics/07.xx-auction-kpi-dashboards.md | New | Funnel, time-to-first-bid, liquidity. |
| Proposed: docs/stories/07.admin-analytics/07.xx-moderation-queue.md | New | Creator content/IP attestations, reports. |
| docs/stories/08.mobile-experience/08.02-camera-integration.md | Keep | Capture for creators. |
| docs/stories/08.mobile-experience/08.03-photo-library-access.md | Keep | Upload existing media. |
| docs/stories/08.mobile-experience/08.03.02-microphone-audio-recording.md | Keep | Voiceovers. |
| docs/stories/08.mobile-experience/08.04-app-performance-optimization.md | Keep | Performance baseline. |
| docs/stories/08.mobile-experience/08.01.04-deep-linking-app-indexing.md | Adjust | Deep links to item details/auctions. |
| docs/stories/08.mobile-experience/08.02.03-push-notifications.md | Adjust | Enable for auction events (N+1). |
| docs/stories/09.platform-infrastructure/09.01-rest-api-architecture.md | Keep | API foundation. |
| docs/stories/09.platform-infrastructure/09.09-event-streaming.md | Keep | Telemetry and realtime backbone. |
| docs/stories/09.platform-infrastructure/09.16-cloud-storage-integration.md | Keep | Media storage. |
| docs/stories/09.platform-infrastructure/09.18-database-architecture.md | Keep | Data schemas. |
| docs/stories/09.platform-infrastructure/09.19-file-storage-management.md | Keep | Media files management. |
| docs/stories/09.platform-infrastructure/09.07-video-processing-integration.md | Keep | Composition/processing. |
| docs/stories/09.platform-infrastructure/09.05-payment-gateway-integration.md | Adjust (defer) | Revisit post-pilot. |
| docs/stories/09.platform-infrastructure/09.99-auction-service-mvp.md | New | Create/open auction; place/list bids; lifecycle/timers. |
| Proposed: docs/stories/09.platform-infrastructure/09.xx-feature-flags-and-remote-config.md | New | Flag/kill switch for auctions. |
| docs/stories/09.platform-infrastructure/09.21-feature-flags-and-remote-config.md | New | Flag/kill switch, region allowlist (UA), allowlisted creators. |
| docs/stories/07.admin-analytics/07.04-auction-kpi-dashboards.md | New | Pilot KPI dashboards and event health. |

Near‑term milestones (next 1–2 sprints):
- Sprint N (pilot/buyer-first): buyer CTA → bid → auction open → details with bids; minimal creator publish (manual seed); telemetry; feature flag + kill switch.
- Sprint N+1: creator studio MVP (project, uploads, composition, publish); auction enhancements (timer/anti-snipe), basic notifications, moderation guardrails.

---

## 5) Pivot pilot (thin vertical slice)
Hypothesis:
- If we enable buyers to propose bids directly from the feed on handmade items, we will see meaningful engagement (≥3% bid proposal rate) and active auctions that validate liquidity, because the video-first format lowers friction and increases perceived uniqueness/urgency.

Scope:
- Buyer slice end‑to‑end: open app → scroll feed → see item overlay → tap "Propose bid" → enter amount → confirm → success → auction visible in feed/details → view bids history.

Acceptance criteria:
- AC1: From any feed video with an item overlay, user can open a bid modal, enter a valid amount, confirm, and receive a success state.
- AC2: First valid bid creates/opens an auction and displays active state in feed and on the item details page.
- AC3: Bids history shows chronological entries with bidder obfuscation (e.g., masked handle) and timestamps.
- AC4: Realtime updates reflect new bids within ≤2s on details page (polling acceptable in pilot ≤10s).
- AC5: Input validation prevents invalid bids; clear error states; event logging succeeds ≥99%.
 - AC6: Bid validation enforces a fixed minimum increment of +1 USD over current highest bid.

Telemetry:
- Events: feed_impression, cta_propose_bid_tap, bid_amount_entered, bid_submitted, bid_confirmed, auction_opened, bids_list_viewed, auction_state_changed, error_toast_shown.
- Dashboards: funnel (impression → CTA → submit → confirm), time-to-first-bid, bids per auction, error rates.

Risk/rollback plan:
- Feature flag the bid/auction feature; kill switch disables CTA and hides indicators; limit pilot to internal/allowlisted creators and regions.
 - Region gating: Ukraine-only for pilot; enforce in client surfaces and server APIs.

Owner(s) and duration:
- DRIs: PO (User), Eng Lead (TBD), Design (TBD)
- Estimated effort: ~2 sprints for buyer-first pilot; +1 sprint for creator studio MVP.

---

## 6) Risks and unknowns
Top risks (probability × impact × mitigation):
- R1: Auction legality/compliance varies by region — P:M I:H — Mitigation: narrow pilot regions; add disclosures/ToS; consult legal before broad rollout.
- R2: Shill bidding/fraud undermines trust — P:M I:H — Mitigation: rate limits, identity verification for creators, anomaly detection, manual review during pilot.
- R3: Content moderation and IP ownership — P:M I:M — Mitigation: creator attestations, report flows, basic moderation queue.
- R4: Realtime scalability/latency — P:L I:M — Mitigation: pilot with small cohort; choose scalable messaging; fallback to polling.

Unknowns to spike:
- Spike #1: Auction rules (increments, timer, anti-snipe) — Approach: define MVP rules and simulate; Timebox: 3 days.
- Spike #2: Realtime channel approach for Flutter (WebSockets vs. Firebase/Streams) — Approach: prototype both with load test; Timebox: 3 days.
- Spike #3: Video composition pipeline on-device vs server — Approach: compare UX/perf/cost; Timebox: 3 days.
- Spike #4: Compliance checklist for auctions — Approach: legal review + industry references; Timebox: 2 days.

---

## 7) Decision and next steps
Decision owner: Product Owner (User)  
Target decision date: TBD (suggest 2025-10-06)

Go/no‑go criteria recap:
- Bid proposal rate ≥3% in pilot cohort.
- Median time-to-first-bid ≤2 minutes for auctioned items.
- Event error rate <1%; no critical compliance blockers.

Immediate next steps:
- [ ] Confirm scope and non‑negotiables
- [ ] Align on KPIs and telemetry
- [ ] Tag backlog (Keep/Adjust/Drop) and draft New stories
- [ ] Define pilot slice ACs and owners
- [ ] Prepare ADR referencing this brief
- [ ] Schedule stakeholder review

---

## 8) Appendix
- Links to research/market data:
- References to existing docs:
- Notes:
	- Platforms: Android, iOS, Web (Flutter app)
	- Compliance/Security notes: assess auction regulations, user age restrictions, IP rights, data retention/minimization.
