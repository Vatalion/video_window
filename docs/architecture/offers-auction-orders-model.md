# Offers → Auction → Orders — Data Model & State Machine (MVP)

This document outlines core entities, relationships, and state machines for the MVP flows: Offers, Auction lifecycle, and Orders (post‑payment).

## Entities (Core)

- User
  - id, handle, displayName, avatarUrl, role (buyer|maker)
- MakerProfile
  - id, userId, offerPolicy: { autoRejectBelowAmount, currency, enabled }
- ArtifactStory
  - id, makerId, title, category, shortDescription, heroMedia, gallery[], timeline[], materials[], notes, location?, status (Listed|Sold|Archived)
- Offer
  - id, storyId, buyerId, amount, currency, note?, createdAt, status (Pending|AutoRejected|Rejected|Accepted|Superseded)
  - flags: isOpening (true if first non‑rejected), source (offer|bid)
- Auction
  - id, storyId, openAt, closeAt?, softClosePolicyTier (48|72|96), totalCapAt, highestBidId?, status (NotOpen|Open|Locked|Closed)
- Bid
  - id, auctionId, buyerId, amount, createdAt, status (Valid|Invalid|Retracted)
- SaleLock
  - id, storyId, auctionId?, buyerId, amount, lockedAt, reason (MakerAccepted|AutoAtCap), expiresAt (payment window end)
- Payment
  - id, saleLockId, status (Pending|Succeeded|Failed|Expired), pspTxnId?, amount, currency, createdAt, updatedAt
- Order
  - id, storyId, buyerId, amount, currency, status (AwaitingShipment|InTransit|Delivered|Completed|Cancelled), paidAt, shipByAt, deliveredAt?, completedAt?
- Shipment
  - id, orderId, carrier, trackingNumber, shipDate, status (LabelCreated|InTransit|OutForDelivery|Delivered)
- Issue
  - id, orderId, buyerId, type, details, photos[], openedAt, status (Open|Resolved|Dismissed)

## Relationships

- User 1—1 MakerProfile (optional)
- MakerProfile 1—N ArtifactStory
- ArtifactStory 1—N Offers
- ArtifactStory 1—1 Auction (active or historical record)
- Auction 1—N Bids
- SaleLock 1—1 Payment
- Payment 1—1 Order (on success)
- Order 1—1 Shipment (MVP single shipment)
- Order 1—N Issues (MVP: 0 or 1 typical)

## State Machines

### Offers/Auction (Story‑centric)

States: Listed → Auction.Open → Auction.Locked → Auction.Closed

- Listed
  - On Offer.Submit
    - If first offer and maker Rejects immediately → stay Listed; Offer.status=Rejected
    - If first offer and not rejected → Open auction; mark offer as opening (Offer.status=Accepted → becomes highest)
    - If auction previously closed and story not sold → new first non‑rejected offer can open a new auction
- Auction.Open
  - On Bid.Place (amount ≥ max(1%, 5 units) above highest) → update highest; reset soft‑close; enforce total cap 7 days
  - On Maker.Accept → Auction.Locked (SaleLock created; buyer payment window starts)
  - On Time.ReachTotalCap → Auction.Closed (SaleLock created for highest; proceed to Payment)
- Auction.Locked
  - On Payment.Succeeded → Auction.Closed (Story.status=Sold; create Order)
  - On Payment.Expired/Failed → unlock: Maker may Accept next‑highest within 24h or return Story to Listed
- Auction.Closed
  - Terminal for the auction; Story either Sold (if payment succeeded) or back to Listed if not

Timers/Policies:
- Soft‑close: base 48h; tiers 48/72/96 by popularity; +24h if highest > $1k; reset on new valid bid; total cap 7 days.
- Payment window: 24h from SaleLock.lockedAt; expiration triggers next‑highest accept or return to Listed.

### Orders (Post‑Payment)

States: AwaitingShipment → InTransit → Delivered → Completed

- AwaitingShipment
  - On Maker.AddTracking → InTransit
  - On Time.Now > shipByAt (paidAt+72h) → Overdue flag; buyer eligible to cancel (policy); on Cancel → Cancelled
- InTransit
  - On Tracking.Delivered → Delivered (set deliveredAt)
- Delivered
  - On Time.Now < deliveredAt+48h and Buyer.ReportIssue → Issue.Open (order remains Delivered until resolution)
  - On Time.Now ≥ deliveredAt+7d and no open issue → Completed (auto‑complete)
- Completed (terminal)

### Payment

States: Pending → Succeeded|Failed|Expired

- Pending
  - On PSP.Succeeded → Succeeded (create Order; shipByAt=paidAt+72h)
  - On PSP.Failed (hard) → Failed
  - On Time.Now ≥ expiresAt → Expired

## Derived Fields & Constraints

- minNextBid = max(ceil(highest*0.01), 5 units)
- shipByAt = paidAt + 72h
- issuesWindowEnd = deliveredAt + 48h
- autoCompleteAt = deliveredAt + 7d

## Audit & Idempotency

- All transitions emit events with idempotency keys; replays do not duplicate state changes.
- Monetary transitions (Payment → Order) are idempotent and atomic.

## Notes

- MVP assumes a single currency per transaction; multi‑currency and tax locality expansion later.
- Notifications derive from events; delivery via push/email is out of scope for MVP but preferences are stored.
