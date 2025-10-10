# MVP Analytics Events — Mapping to ACs & Wireframes

This document defines analytics events, parameters, and their mapping to acceptance criteria (AC IDs) and wireframe steps.

## Conventions
- user_id, story_id, maker_id, order_id use anonymized IDs.
- currency amounts reported in minor units (e.g., cents) where applicable.
- All events include context: app_version, platform, locale, referrer, screen.

## Feed
- event: feed_viewed — params: position_start, session_id — maps: AC-FEED-1..5
- event: feed_item_impression — params: story_id, maker_id, position — maps: AC-FEED-4
- event: feed_like_tapped — params: story_id, liked(bool) — maps: AC-FEED-5
- event: feed_longpress_actions_opened — params: story_id — maps: AC-FEED-5
- event: feed_view_story_tapped — params: story_id — maps: AC-FEED-1,3

## Story
- event: story_viewed — params: story_id, source(feed|share|deep_link) — maps: AC-STORY-1..5
- event: story_share — params: story_id, channel — maps: AC-SHARE-1..3
- event: story_primary_cta — params: story_id, cta(i_want_this) — maps: AC-STORY-3

## Offers & Auction
- event: offer_opened — params: story_id — maps: AC-OA-CONTROL-1
- event: offer_submitted — params: story_id, amount, currency, note_present — maps: AC-OA-STATE-1
- event: offer_auto_rejected — params: story_id, threshold, amount — maps: AC-MAKER-1
- event: auction_opened — params: story_id, opening_bid — maps: AC-OA-STATE-1
- event: bid_opened — params: story_id — maps: AC-OA-CONTROL-2
- event: bid_submitted — params: story_id, amount, min_next_bid — maps: AC-OA-CONTROL-3
- event: bid_rejected_min_increment — params: story_id, amount, min_next_bid — maps: AC-OA-CONTROL-3
- event: auction_softclose_reset — params: story_id, new_expiry_at — maps: AC-TIME-2
- event: auction_accepted_by_maker — params: story_id, amount, buyer_id — maps: AC-OA-STATE-4
- event: auction_auto_closed_at_cap — params: story_id, amount — maps: AC-TIME-3

## Payment / Checkout
- event: payment_required_viewed — params: story_id, total, time_left_sec — maps: AC-CHK-1
- event: checkout_started — params: story_id — maps: AC-CHK-3
- event: checkout_address_submitted — params: has_validation_errors(bool), country — maps: AC-CHK-4
- event: checkout_payment_submitted — params: psp_token_present(bool) — maps: AC-CHK-5
- event: checkout_review_viewed — params: total — maps: AC-CHK-6
- event: checkout_pay_clicked — params: total — maps: AC-CHK-6
- event: payment_succeeded — params: order_id, amount — maps: AC-CHK-8, AC-PAY-4
- event: payment_failed — params: reason(code), retryable(bool) — maps: AC-CHK-7
- event: payment_expired — params: story_id — maps: AC-CHK-2, AC-PAY-3

## Orders (Buyer)
- event: orders_list_viewed — params: section — maps: AC-ORD-B-1
- event: order_viewed — params: order_id, status — maps: AC-ORD-B-2,6
- event: tracking_updated — params: order_id, status — maps: AC-ORD-B-3
- event: order_delivered — params: order_id — maps: AC-ORD-B-4
- event: issue_report_opened — params: order_id — maps: AC-ORD-B-4
- event: issue_report_submitted — params: order_id, type — maps: AC-ORD-B-4
- event: order_autocompleted — params: order_id — maps: AC-ORD-B-5

## Orders (Maker)
- event: to_ship_viewed — params: count — maps: AC-ORD-M-1
- event: add_tracking_opened — params: order_id — maps: AC-ORD-M-2
- event: tracking_saved — params: order_id, carrier — maps: AC-ORD-M-2
- event: order_overdue_ship — params: order_id, ship_by_at — maps: AC-ORD-M-3

## Maker Dashboard
- event: maker_dashboard_viewed — params: active_auctions, offers_to_review, orders_to_ship — maps: AC-MKD-1
- event: offers_list_viewed — params: count — maps: AC-MKD-2
- event: maker_accept_clicked — params: story_id, amount — maps: AC-MKD-3
- event: offer_policy_updated — params: threshold — maps: AC-MKD-4
- event: notification_prefs_updated — params: offers, bids, orders — maps: AC-MKD-5

## Privacy & PII
- No raw card data, addresses, or email/phone included in analytics payloads; use hashed or redacted fields if needed for attribution.
- Respect user privacy settings; include consent flags in context.
