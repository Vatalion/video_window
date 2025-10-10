# MVP Acceptance Criteria — Craft Video Marketplace

This document lists testable acceptance criteria for the MVP, aligned to the feed, story, offers/auction, payments, and shipping flows.

## Identity & Social Login
- AC-AUTH-1: Given the Sign in screen, Then “Continue with Apple” (iOS) and “Continue with Google” buttons are visible and enabled.
- AC-AUTH-2: Given a new user, When Apple/Google sign-in completes, Then a new account is created and the user lands on the Feed signed in.
- AC-AUTH-3: Given provider returns name/email (or Apple relay email), Then Profile shows display name and email; display name can be edited.
- AC-AUTH-4: Given sign-in is cancelled/denied, Then the user remains on the Sign in screen and an inline message explains the cancellation; no account/session is created.
- AC-AUTH-5: Given an existing account with the same verified email, When signing in with another provider, Then a “Link accounts” prompt appears and, upon confirm, both providers sign into the same account.
- AC-AUTH-6: Given Settings → Account, Then linked providers are listed; the user can link the other provider and can unlink only if at least one sign-in method remains.
- AC-AUTH-7: Given the user taps Sign out, Then they return to the Sign in screen and protected screens require sign-in.
- AC-AUTH-8: Given a transient error during provider sign-in or token exchange, Then an inline error with Retry is shown; no partial account is created.
- AC-AUTH-9: Given auth flows start/end, Then events auth_start, auth_success, auth_cancel, and auth_error are emitted with provider and (for error/cancel) reason.

## Feed
- AC-FEED-1: Given the feed is visible, When a user taps the video/card, Then the Artifact Story opens (never the auction).
- AC-FEED-2: Given the feed is visible, When viewing the right rail, Then Like, Save, Share, Follow, and More icons appear (with counts).
- AC-FEED-3: Given the feed is visible, When the bottom pill is shown, Then it reads “View Story” and opens the Artifact Story.
- AC-FEED-4: Given the feed is visible, Then no auction info (status, price, bids, timer) is displayed.
- AC-FEED-5: Given the feed, When user double-taps the video, Then it likes the item; When long-pressing, Then quick actions show (Save/Share/Not interested).

## Story — Core
- AC-STORY-1: Given the Story page, Then Header shows maker avatar/handle, Follow, Share, More (share count visible).
- AC-STORY-2: Given the Story, Then the hero media is playable with scrub; gallery thumbnails appear below if images exist.
- AC-STORY-3: Given the Story, Then “I want this” is the primary CTA and scrolls to Offers & Auction.
- AC-STORY-4: Given the Story, Then sections exist: Overview (title, category, ≤140-char short description), Process Timeline (optional), Materials & Tools, Notes, optional Location.
- AC-STORY-5: Given the Story, Then Like and Save are available with counts; Comments are deferred (not present in MVP).

## Offers & Auction — Copy
- AC-OA-COPY-1: Given the Offers & Auction section, Then the intro text is exactly: “Make an offer to the creator for a chance to acquire this item.”
- AC-OA-COPY-2: Given the Offers & Auction section, Then the hint text is exactly: “The creator can accept or reject your proposal. Until accepted, anyone can outbid your offer.”

## Offers & Auction — States
- AC-OA-STATE-1: Given no auction is open, When the first offer is submitted and not immediately rejected, Then the auction opens and that offer becomes the opening bid.
- AC-OA-STATE-2: Given the first offer is immediately rejected by the maker, Then no auction starts and the item remains Listed.
- AC-OA-STATE-3: Given an auction is open, When a higher bid is placed, Then the current highest bid updates and the soft-close timer resets.
- AC-OA-STATE-4: Given an auction is open, When the maker accepts, Then the sale locks to the current high bidder and proceeds to payment.

## Offers & Auction — Controls
- AC-OA-CONTROL-1: Given no auction is open, Then the Offer form shows: amount input (currency-aware), optional note, quick suggestions 50/100/250, Round up, and Custom.
- AC-OA-CONTROL-2: Given an auction is open, Then the Bid form shows: amount input, quick picks +5%, +10%, +25%, ×2, ×3, Round up; actions Place bid and Watch auction.
- AC-OA-CONTROL-3: Given any bid submission, Then validation enforces minimum next bid = max(1%, 5 units) above current highest; invalid inputs disable submit and show inline error.
- AC-OA-CONTROL-4: Given the auction view, Then it displays highest bid, time left (soft-close), and watchers/bidders count.

## Soft-Close & Timing
- AC-TIME-1: Given an auction is open, Then soft-close duration applies per policy: base 48h, popularity tiers 48/72/96h, +24h if current bid > $1k, and total cap 7 days.
- AC-TIME-2: Given a new valid bid is placed, Then the soft-close timer resets (extends) according to the current tiered duration.
- AC-TIME-3: Given the auction reaches the total cap (7 days) without acceptance, Then the auction ends automatically (winner is highest bid at cap).

## Maker Actions
- AC-MAKER-1: Given an offer arrives, When the amount is below the maker’s “auto-reject below X” threshold, Then the platform auto-rejects with a standard message and notifies the buyer.
- AC-MAKER-2: Given offers or bids exist, When the maker taps Accept, Then the sale locks to the current high bidder; subsequent bids are blocked.
- AC-MAKER-3: Given the first offer was immediately rejected, Then the item remains Listed and can receive new offers (which can start a new auction if not immediately rejected).

## Payment
- AC-PAY-1: Given the maker accepts, Then the buyer sees “Pay now” with a 24h payment window.
- AC-PAY-2: Given payment is pending, Then reminders fire at T−12h and T−2h.
- AC-PAY-3: Given payment fails or expires (24h), Then the seller may accept the next-highest bid within 24h or return the item to Listed.
- AC-PAY-4: Given payment succeeds, Then the order state becomes Awaiting Shipment.

## Shipping & Orders
- AC-SHIP-1: Given payment succeeded, Then buyer’s shipping address is collected (at payment) and shown to seller.
- AC-SHIP-2: Given Awaiting Shipment, Then seller must provide carrier + tracking and mark Shipped within 72h; otherwise the buyer can cancel for a full refund.
- AC-SHIP-3: Given Shipped, Then tracking is visible to the buyer; states flow Shipped → Delivered → Completed (auto-complete 7 days after delivery if no buyer confirmation).
- AC-SHIP-4: Given Delivered, Then the buyer can report an issue within 48h; platform records the case for manual resolution.

## Share & Deep Links
- AC-SHARE-1: Given Share is triggered (feed or Story), Then the native share sheet opens with a deep-link to the Artifact Story.
- AC-SHARE-2: Given the link is shared externally, Then the OG preview shows title, hero image, and maker; no live auction details are embedded.
- AC-SHARE-3: Given shares occur, Then share counts update on feed right rail and Story header.

## Accessibility & Interaction
- AC-A11Y-1: Given interactive controls (icons, buttons, chips), Then each tap target is ≥44px and keyboard-focusable on web.
- AC-A11Y-2: Given the hero video, Then captions can be toggled on/off (if captions uploaded).
- AC-UX-1: Given the feed, Then swipe up/down navigates; double-tap likes; long-press shows quick actions.

## Checkout
- AC-CHK-1: Given a buyer is eligible to pay after acceptance, When opening the Payment required screen, Then the total amount (subtotal, fees/tax, total) and a 24h countdown timer are displayed with a “Pay now” action.
- AC-CHK-2: Given the payment window expires, When the buyer returns to the Payment required or Checkout screens, Then “Pay now” is disabled and a message explains the window expired and the creator may accept the next-highest offer.
- AC-CHK-3: Given Checkout is started, Then it presents a stepper with steps Address → Payment → Review → Done.
- AC-CHK-4: Given the Address step, When required fields are incomplete or invalid per country rules, Then Continue is disabled and inline validation errors are shown focused to the first error.
- AC-CHK-5: Given the Payment step, When card details are incomplete/invalid, Then Continue is disabled and inline validation errors render; raw card data is not stored by the app (tokenized via PSP).
- AC-CHK-6: Given the Review step, Then the artifact summary, shipping address, itemized charges, and policy notes (ship-by 72h; 48h issues window) are shown; When tapping Pay, Then a single submission is enforced (no double-submit) and a loading state appears.
- AC-CHK-7: Given a transient PSP error occurs during Pay, Then an error message appears with a retry option; the 24h timer continues.
- AC-CHK-8: Given payment succeeds, Then the Done step appears with an order number and actions “View order” and “Back to story”; the order state is Awaiting Shipment.
- AC-CHK-9: Given a saved address exists, When selecting “Use saved address”, Then the fields prefill and can be edited before continuing.
- AC-CHK-10: Given the 24h timer, Then it is consistent across Payment required and Checkout screens and blocks payment after expiry.

## Orders — Buyer
- AC-ORD-B-1: Given the Orders list, Then orders are grouped by status (Awaiting shipment, In transit, Delivered, Completed) and each entry shows id, title, price, and ship-by date when Awaiting shipment.
- AC-ORD-B-2: Given Order detail, Then it shows artifact summary, amount paid with timestamp, current status, shipping address, and shipment panel with tracking (or “Not yet shipped”).
- AC-ORD-B-3: Given the maker adds tracking, Then the buyer sees carrier, tracking number, and a timeline that progresses through Label created → In transit → Out for delivery → Delivered.
- AC-ORD-B-4: Given an order is Delivered, Then the issues window countdown (48h) is shown and “Report an issue” is enabled only within that window.
- AC-ORD-B-5: Given 7 days pass after delivery with no open issue, Then the order auto-completes to Completed.
- AC-ORD-B-6: Given Order detail, Then actions “Contact maker” and “View story” are available.

## Orders — Maker
- AC-ORD-M-1: Given the To Ship list, Then each order shows id, title, amount, and a ship-by date computed as payment_time + 72h.
- AC-ORD-M-2: Given Add tracking, When the maker saves carrier, tracking number, and ship date, Then the order status changes to In transit and buyer tracking becomes visible.
- AC-ORD-M-3: Given an order remains Awaiting shipment past 72h, Then the UI highlights the overdue state and the buyer becomes eligible to cancel for a full refund (per policy).
- AC-ORD-M-4: Given tracking updates indicate Delivered, Then the order state shows Delivered and will auto-complete after 7 days if no issue is opened.

## Maker Dashboard
- AC-MKD-1: Given the Maker Dashboard, Then it displays counts for Active auctions, Offers to review, and Orders to ship.
- AC-MKD-2: Given Offers exist, Then the Offers view lists incoming offers per story with actions Accept and Reject and a link to View story.
- AC-MKD-3: Given an active auction, Then the Auction detail shows highest bid and time left and provides “Accept current” to lock the sale (respecting auction rules).
- AC-MKD-4: Given Settings → Offer policy, Then editing the “Auto-reject below X” threshold persists and influences subsequent offers per AC-MAKER-1.
- AC-MKD-5: Given Notifications settings, Then toggles exist for Offers, Bids, and Orders (MVP: preference storage only; delivery mechanics are out of scope).
