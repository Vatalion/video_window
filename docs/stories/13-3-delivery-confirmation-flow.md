# Story 13-3: Delivery Confirmation Flow

## Status
Ready for Dev

## Story
**As a** buyer,
**I want** to confirm receipt of my order and provide feedback,
**so that** the transaction can be completed and the maker can be paid

## Acceptance Criteria
1. Buyer receives notification when package is delivered (carrier confirmation) with delivery timestamp, photo proof (if available), and confirmation prompt.
2. Buyer can mark order as received within app with optional rating/feedback and confirmation that item matches description and condition.
3. **BUSINESS CRITICAL**: Order auto-completes 7 days after delivery if no issues reported, triggering payment release to maker and closing transaction lifecycle.
4. Buyer can report delivery issues before auto-completion with issue categorization (not received, damaged, wrong item, quality issue) and evidence upload.
5. Maker receives notification when order is marked complete with buyer feedback, final payment release confirmation, and transaction summary.
6. **BUSINESS CRITICAL**: Payment is released to maker after completion confirmation via Stripe Connect transfer with 2-3 business day deposit timeline and fee deduction.

## Prerequisites
1. Story 13.2 – Tracking Integration System (delivery event tracking and status updates)
2. Story 12.1 – Stripe Checkout Integration (payment capture and Connect setup)
3. Story 11.1 – Notification System (delivery and completion notifications)
4. Story 13.4 – Shipping Issue Resolution (issue reporting and escalation workflow)

## Tasks / Subtasks

### Phase 1 – Delivery Notification System

- [ ] Process carrier delivery webhook events (AC: 1) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Handle "delivered" tracking event from carrier webhooks (Story 13.2)
  - [ ] Extract delivery timestamp and location from tracking data
  - [ ] Retrieve delivery photo if provided by carrier (signature/doorstep photo)
  - [ ] Update order status to "delivered" with delivery_confirmed_at timestamp
  - [ ] Store delivery proof metadata (photo URL, signature name) in order entity
- [ ] Create buyer delivery notification (AC: 1) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Build `OrderDeliveredNotification` with delivery details
  - [ ] Include delivery timestamp, photo proof, and "Confirm Receipt" CTA
  - [ ] Send push notification, email, and SMS (buyer preference)
  - [ ] Deep link to delivery confirmation page in app
  - [ ] Show prominent notification badge on order detail page
- [ ] Build in-app delivery confirmation interface (AC: 2) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Create `DeliveryConfirmationPage` with order summary
  - [ ] Display delivery proof (photo, timestamp, location)
  - [ ] Provide "Confirm Receipt" button with optional rating (1-5 stars)
  - [ ] Enable feedback text field for buyer comments on item/experience
  - [ ] Show "Report Issue" alternative action if problems exist

### Phase 2 – Auto-Completion Workflow

- [ ] **BUSINESS CRITICAL**: Implement 7-day auto-completion timer (AC: 3) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Create scheduled job running daily to check delivered orders
  - [ ] Identify orders delivered >7 days ago without completion or issue report
  - [ ] Transition order status to "completed" automatically
  - [ ] Generate auto-completion audit log with reason and timestamp
  - [ ] Trigger payment release workflow (AC: 6) for auto-completed orders
- [ ] Build maker completion notification (AC: 5) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Create `OrderCompletedNotification` for makers
  - [ ] Include buyer feedback/rating if provided
  - [ ] Show payment release details (amount, timeline, transaction ID)
  - [ ] Provide transaction summary with fees breakdown
  - [ ] Deep link to completed order in maker order history
- [ ] **BUSINESS CRITICAL**: Implement payment release via Stripe Connect (AC: 6) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation & docs/tech-spec-epic-12.md – Stripe Connect]
  - [ ] Create transfer from platform Stripe account to maker Connect account
  - [ ] Calculate final payout: (sale_price - platform_fee - stripe_fee)
  - [ ] Set transfer description with order ID and buyer info
  - [ ] Handle transfer failures with retry logic and maker notification
  - [ ] Update order with payout status and Stripe transfer ID
  - [ ] Store payout record for maker earnings dashboard and tax reporting

### Phase 3 – Issue Reporting Integration

- [ ] Add "Report Issue" option before auto-completion (AC: 4) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation & Story 13.4]
  - [ ] Display "Report Issue" button on delivery confirmation page
  - [ ] Navigate to issue reporting form (Story 13.4 implementation)
  - [ ] Prevent auto-completion if issue reported (hold payment)
  - [ ] Show buyer that issue reporting stops payment release timer
  - [ ] Provide estimated resolution timeline (3-5 business days)
- [ ] Hold payment pending issue resolution (AC: 4, 6) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
  - [ ] Flag order with payment_hold status when issue reported
  - [ ] Prevent auto-completion while issue is open
  - [ ] Display hold status in maker order detail with reason
  - [ ] Release payment only after issue resolved or buyer confirmation
  - [ ] Alert maker to issue with guidance on resolution process
- [ ] Integrate with customer support escalation (AC: 4) [Source: docs/tech-spec-epic-13.md – Delivery Confirmation & Story 13.4]
  - [ ] Route severe issues (not received, major damage) to support team
  - [ ] Create support ticket linked to order and issue report
  - [ ] Notify support team of high-priority fulfillment issues
  - [ ] Track resolution timeline against SLA (5 business days max)
  - [ ] Escalate to platform admin if unresolved beyond SLA

## Dev Notes

### Previous Story Insights
- This is the third story in Epic 13, completing the buyer side of the fulfillment lifecycle. It integrates with Story 13.2 (tracking events) and Story 13.4 (issue resolution) to ensure fair transaction completion and payment release.

### Data Models
- `Order` entity adds: delivered_at, confirmed_at, completed_at, payment_released_at, buyer_rating, buyer_feedback, completion_type (manual/auto). [Source: docs/tech-spec-epic-13.md – Data Models]
- `PayoutRecord` entity: order_id, maker_id, gross_amount, platform_fee, stripe_fee, net_payout, stripe_transfer_id, released_at. [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
- Order status progression: delivered → confirmed/auto_completed → payment_released. [Source: docs/tech-spec-epic-13.md – Data Models]

### API Specifications
- `POST /orders/{id}/confirm-delivery` accepts buyer rating/feedback and transitions order to completed status. [Source: docs/tech-spec-epic-13.md – Delivery Confirmation]
- `POST /orders/{id}/release-payment` triggers Stripe Connect transfer with fee calculations and payout record creation.
- `GET /orders/pending-completion` returns delivered orders approaching auto-completion deadline for buyer reminder notifications.
- Stripe Connect Transfer API: Create transfer from platform account to maker Connect account with metadata and description.

### Component Specifications
- Delivery confirmation UI in `video_window_flutter/packages/features/commerce/lib/presentation/pages/delivery_confirmation_page.dart`. [Source: docs/tech-spec-epic-13.md – Source Tree]
- Payment release service in `video_window_flutter/packages/core/lib/services/payments/payout_service.dart` handles Stripe Connect transfers.
- Server delivery endpoints in `video_window_server/lib/src/endpoints/orders/delivery.dart` manage confirmation and completion workflows.
- Scheduled job `auto_complete_delivered_orders` in `video_window_server/lib/src/jobs/` runs daily to process 7-day auto-completions.
- Integration with Stripe Connect for payment release (Epic 12 foundation) and issue resolution system (Story 13.4) for dispute handling.

## Dev Agent Record

### Context Reference

- `docs/stories/13-3-delivery-confirmation-flow.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-06 | v0.1 | Initial story creation | Bob (SM) |
