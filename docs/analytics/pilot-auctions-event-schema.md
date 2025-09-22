# Pilot Auctions — Event Schema

Status: Draft

Purpose: Standardize events and payloads for the auctions pilot to support KPI dashboards and health monitoring.

## Events

- feed_impression
  - props: { itemId, shortVideoId, region, userType: buyer|creator|guest }
- cta_propose_bid_tap
  - props: { itemId, auctionId?, region }
- bid_amount_entered
  - props: { itemId, auctionId?, amount, currency: "USD" }
- bid_submitted
  - props: { itemId, auctionId?, amount, currency: "USD" }
- bid_confirmed
  - props: { itemId, auctionId, amount, currency: "USD" }
- auction_opened
  - props: { itemId, auctionId, startAt, minIncrement: 1, currency: "USD" }
- auction_state_changed
  - props: { auctionId, state: open|ended, at }
- bids_list_viewed
  - props: { itemId, auctionId }
- item_details_viewed
  - props: { itemId, auctionId? }
- ff_exposed
  - props: { key, variant }
- ff_decision
  - props: { key, variant, reason }
- error_toast_shown
  - props: { context: bid_modal|details|feed, code, message }
- error_api
  - props: { endpoint, code, message }

## Conventions
- No PII; use stable anonymous IDs.
- All timestamps in ISO8601 UTC.
- Amounts in currency minor units or decimal with 2dp; currency = "USD" for pilot.

## KPI definitions
- Bid proposal rate = bid_submitted / feed_impression (same cohort + time window)
- Time-to-first-bid = auction_opened.timestamp - first feed_impression for that item in cohort
- Liquidity = % of auctions with ≥2 bid_confirmed within 24h of auction_opened
