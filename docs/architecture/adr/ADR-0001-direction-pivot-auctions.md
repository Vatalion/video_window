# ADR-0001: Pivot to Craftsmen Auctions with Bid-from-Feed

Date: 2025-09-22
Status: Proposed
Deciders: Product Owner, Eng Lead, Design Lead, QA Lead, Legal/Compliance (TBD)
Supersedes: None
Related: ../..//direction-change/2025-09-22-direction-change-brief.md

## Context

We are pivoting from a TikTok-like shop to a service for craftsmen/creators of unique handmade goods. Viewers can propose a bid from short videos, opening an auction for the featured item. The Direction Change Brief captures the vision, scope, and KPIs.

Constraints/Guardrails:
- Platforms: Android, iOS, Web (Flutter app)
- Timeline: No fixed deadline; prioritize safe, measurable pilot
- Budget: Unlimited for implementation
- Compliance: To be assessed; initial pilot limited to low-risk regions

## Decision

Adopt an auction-first product direction with the following technical approach for the pilot:
1) Feature-flagged buyer flow enabling "Propose bid" from the feed.
2) Auction service MVP supporting: create/open auction on first bid, place/list bids, auction state transitions (Open → Ended), and timers.
3) Real-time updates via WebSockets (server) with client fallback polling in pilot; evaluate managed alternatives.
4) Item details page with bids history and active auction state; feed overlay shows badge/timer.
5) Creator studio MVP (next sprint) to compose/publish short videos from uploaded media with item overlay.

## Options considered

1) Keep shop model (no auctions)
- Pros: simpler monetization path (checkout)
- Cons: misaligned with product vision; less differentiation for handmade goods

2) Auctions with managed realtime (e.g., Firebase/Firebase Functions)
- Pros: faster to stand up, scalable
- Cons: platform lock-in; serverless timers for auctions are nuanced; pricing and portability considerations

3) Auctions with custom service + WebSockets (chosen for pilot)
- Pros: control over auction rules/timers; portable; integrates cleanly with Flutter
- Cons: more engineering effort; requires careful scaling and monitoring

## Consequences

- Near-term focus shifts from checkout/payments to auctions and bid UX.
- Compliance/legal review required before broad rollout.
- Introduce new domains: Auction, Bid, Item overlay, Creator studio composition.

## Technical outline (pilot)

Domain entities (MVP):
- Creator {id, handle, verified?}
- Project {id, creatorId, title, description, tags[]}
- MediaAsset {id, projectId, type: video|image, url, metadata}
- ShortVideo {id, projectId, compositionSpec, thumbnailUrl, publishedAt}
- Item {id, projectId, title, description, overlays, status}
- Auction {id, itemId, state: open|ended, reservePrice?, startAt, endAt, minIncrement, antiSnipe?}
- Bid {id, auctionId, bidderId, amount, createdAt}

APIs (REST/HTTP, MVP):
- POST /auctions (on first bid) → {auction}
- POST /auctions/{id}/bids → {bid}
- GET /auctions/{id} → {auction, bids}
- GET /items/{id} → {item, auction?}

Realtime:
- WS channel per auction: events BidPlaced, AuctionOpened, AuctionEnded
- Client fallback: poll GET /auctions/{id} every 10s

Telemetry (events):
- feed_impression, cta_propose_bid_tap, bid_submitted, bid_confirmed, auction_opened, bids_list_viewed, auction_state_changed, error_toast_shown

Security/Compliance (pilot posture):
- Creator content ownership attestation on publish
- Basic rate limiting and anti-abuse on bidding
- Region gating; age-appropriate content policy

Rollout & controls:
- Feature flag for bid/auction surfaces (remote-config)
- Kill switch to hide CTA and auction indicators instantly
- Allowlist pilot cohort (creators, regions)

## Pilot decisions (2025-09-22)

- Pilot region: Ukraine-only; enforce via feature flags and server checks.
- Auction rule MVP: minimum bid increment fixed at +1 USD; anti-snipe optional for pilot.
- Realtime stack MVP: WebSockets with polling fallback; evaluate managed alternatives post-pilot.

## Decision drivers

- Validate buyer demand (bid proposal rate/time-to-first-bid)
- Showcase creator craft via video-first storytelling
- Keep engineering surface small yet end-to-end measurable

## Risks

- Auction legality varies by region → mitigate via region gating and legal review
- Shill bidding/fraud → rate limiting, monitoring, manual review during pilot
- Realtime complexity → start with small cohort; fallback to polling

## Follow-ups

- Define auction rules (increments, timer, anti-snipe) precisely for MVP
- Choose realtime stack (WS vs managed) after a 3-day spike
- Draft ToS disclosures for auctions and bidding
- Instrument dashboards for KPIs
