# EPIC 8 STORY TEMPLATES - READY TO USE

## 8-1-publishing-workflow-implementation.md
```markdown
# Story 8.1: Publishing Workflow Implementation

## Status
**Status:** Ready for Dev

## Story
As a maker, I want to publish my completed stories to the marketplace so that viewers can discover and make offers on my work.

## Acceptance Criteria
- [ ] AC1: Maker can review completed story (all sections: overview, process timeline, materials, notes)
- [ ] AC2: Maker can set minimum offer price before publishing
- [ ] AC3: Maker can preview how story will appear in feed before publishing
- [ ] AC4: Maker can publish story with single "Publish" action
- [ ] AC5: Published story appears in main feed within 5 minutes
- [ ] AC6: Maker receives confirmation notification when story is live

## Tasks
- [ ] Task 1: Create publish story API endpoint
  - [ ] Subtask 1.1: Validate story completeness (all required sections)
  - [ ] Subtask 1.2: Validate minimum price is set and >= $1
  - [ ] Subtask 1.3: Update story status to "published"
  - [ ] Subtask 1.4: Add to feed index for discovery
- [ ] Task 2: Implement publish UI flow
  - [ ] Subtask 2.1: Story review screen with all sections
  - [ ] Subtask 2.2: Minimum price setting interface
  - [ ] Subtask 2.3: Preview mode showing feed appearance
  - [ ] Subtask 2.4: Publish confirmation dialog
- [ ] Task 3: Add feed integration
  - [ ] Subtask 3.1: Feed discovery algorithm inclusion
  - [ ] Subtask 3.2: Real-time feed updates when story published

## Dev Notes
- API: POST /stories/{id}/publish
- Database: Add published_at timestamp, min_offer_price fields
- Feed integration: Use existing recommendation engine
- Validation: Must have video content, overview, and materials sections
```

## 8-2-content-moderation-pipeline.md
```markdown
# Story 8.2: Content Moderation Pipeline

## Status
**Status:** Ready for Dev

## Story
As a platform administrator, I want published content to be automatically reviewed for compliance so that inappropriate content is prevented from reaching viewers.

## Acceptance Criteria
- [ ] AC1: All published stories go through automated moderation checks
- [ ] AC2: Stories flagged by moderation are held in pending review queue
- [ ] AC3: Admin can approve/reject stories in moderation queue
- [ ] AC4: Makers are notified if their story requires manual review
- [ ] AC5: Approved stories automatically go live after admin approval
- [ ] AC6: Rejected stories include feedback for maker improvements

## Tasks
- [ ] Task 1: Implement automated moderation checks
  - [ ] Subtask 1.1: Video content scanning for inappropriate material
  - [ ] Subtask 1.2: Text content filtering for prohibited terms
  - [ ] Subtask 1.3: Image recognition for inappropriate imagery
- [ ] Task 2: Create moderation queue system
  - [ ] Subtask 2.1: Pending review status for flagged content
  - [ ] Subtask 2.2: Admin review interface with content preview
  - [ ] Subtask 2.3: Approve/reject actions with feedback
- [ ] Task 3: Notification system for moderation results
  - [ ] Subtask 3.1: Maker notifications for review status
  - [ ] Subtask 3.2: Admin notifications for queue items

## Dev Notes
- Integration: Third-party content moderation service (AWS Rekognition, Sightengine)
- Database: Add moderation_status, review_notes fields
- Admin interface: Extend existing admin panel
- Notification: Use existing notification system
```

## 8-3-publishing-approval-process.md
```markdown
# Story 8.3: Publishing Approval Process

## Status
**Status:** Ready for Dev

## Story
As a maker, I want to understand the approval process for my published content so that I can ensure compliance and track publication status.

## Acceptance Criteria
- [ ] AC1: Maker can see publication status (draft, pending review, approved, rejected)
- [ ] AC2: Maker receives real-time updates on approval progress
- [ ] AC3: If rejected, maker can see specific feedback and resubmit
- [ ] AC4: Maker can track average approval time and success rate
- [ ] AC5: Maker can withdraw story from review if needed
- [ ] AC6: Approved stories show publication timestamp and feed placement

## Tasks
- [ ] Task 1: Publication status tracking UI
  - [ ] Subtask 1.1: Status indicators in maker dashboard
  - [ ] Subtask 1.2: Progress timeline showing review stages
  - [ ] Subtask 1.3: Status change notifications
- [ ] Task 2: Feedback and resubmission system
  - [ ] Subtask 2.1: Detailed rejection feedback display
  - [ ] Subtask 2.2: One-click resubmission after edits
  - [ ] Subtask 2.3: Edit tracking for resubmitted content
- [ ] Task 3: Analytics dashboard for makers
  - [ ] Subtask 3.1: Approval rate metrics
  - [ ] Subtask 3.2: Average review time display
  - [ ] Subtask 3.3: Publication performance metrics

## Dev Notes
- Real-time updates: WebSocket connection for status changes
- Analytics: Use existing analytics infrastructure
- UI integration: Extend maker dashboard with publication section
- API endpoints: GET /stories/{id}/status, POST /stories/{id}/resubmit
```

## 8-4-story-versioning-and-rollback.md
```markdown
# Story 8.4: Story Versioning and Rollback

## Status
**Status:** Ready for Dev

## Story
As a maker, I want to make updates to published stories and rollback changes if needed so that I can improve content while maintaining publication history.

## Acceptance Criteria
- [ ] AC1: Maker can edit published story content (text, images, process timeline)
- [ ] AC2: Each edit creates a new version with timestamp and changes log
- [ ] AC3: Maker can preview changes before publishing updates
- [ ] AC4: Maker can rollback to any previous version
- [ ] AC5: Version history is visible with change summaries
- [ ] AC6: Active offers/auctions are preserved during content updates

## Tasks
- [ ] Task 1: Version control system
  - [ ] Subtask 1.1: Story version database schema
  - [ ] Subtask 1.2: Change detection and diff generation
  - [ ] Subtask 1.3: Version storage and retrieval APIs
- [ ] Task 2: Edit and update workflow
  - [ ] Subtask 2.1: Edit mode for published stories
  - [ ] Subtask 2.2: Change preview with before/after comparison
  - [ ] Subtask 2.3: Update publication with version increment
- [ ] Task 3: Rollback functionality
  - [ ] Subtask 3.1: Version history browser interface
  - [ ] Subtask 3.2: One-click rollback to previous version
  - [ ] Subtask 3.3: Rollback impact validation (preserve offers)

## Dev Notes
- Database: story_versions table with content snapshots
- Offers preservation: Version changes don't affect active commerce
- Change detection: JSON diff for structured content changes
- API: POST /stories/{id}/versions, GET /stories/{id}/versions, POST /stories/{id}/rollback/{version}
```

---

# EPIC 13 STORY TEMPLATES - READY TO USE

## 13-1-shipping-address-management.md
```markdown
# Story 13.1: Shipping Address Management

## Status
**Status:** Ready for Dev

## Story
As a winning bidder, I want to provide accurate shipping information during checkout so that my purchased item can be delivered successfully.

## Acceptance Criteria
- [ ] AC1: Buyer can enter shipping address during Stripe checkout
- [ ] AC2: Address validation ensures deliverable location
- [ ] AC3: Buyer can save multiple addresses for future purchases
- [ ] AC4: International shipping restrictions are enforced per item
- [ ] AC5: Shipping cost calculation is shown before payment
- [ ] AC6: Address changes are possible before maker ships item

## Tasks
- [ ] Task 1: Stripe checkout address integration
  - [ ] Subtask 1.1: Configure Stripe checkout for address collection
  - [ ] Subtask 1.2: Address validation API integration
  - [ ] Subtask 1.3: International shipping rules enforcement
- [ ] Task 2: Address management system
  - [ ] Subtask 2.1: User address book functionality
  - [ ] Subtask 2.2: Default shipping address setting
  - [ ] Subtask 2.3: Address change workflow pre-shipment
- [ ] Task 3: Shipping cost calculation
  - [ ] Subtask 3.1: Integration with shipping provider APIs
  - [ ] Subtask 3.2: Dynamic cost display during checkout
  - [ ] Subtask 3.3: International shipping premium calculation

## Dev Notes
- Stripe integration: Shipping address collection in checkout session
- Address validation: Google Maps API or similar service
- Shipping providers: USPS, FedEx, UPS APIs for cost calculation
- Database: user_addresses table, order shipping_address field
```

## 13-2-tracking-integration-system.md
```markdown
# Story 13.2: Tracking Integration System

## Status
**Status:** Ready for Dev

## Story
As a maker, I want to easily add tracking information for shipped orders so that buyers can monitor delivery progress and I can prove shipment.

## Acceptance Criteria
- [ ] AC1: Maker can add tracking number and carrier within 72 hours of sale
- [ ] AC2: Tracking information is automatically validated with carrier
- [ ] AC3: Buyer receives notification with tracking details immediately
- [ ] AC4: Order status updates automatically based on tracking events
- [ ] AC5: Maker dashboard shows all pending shipments requiring tracking
- [ ] AC6: System sends reminders if tracking not added within 48 hours

## Tasks
- [ ] Task 1: Tracking input interface for makers
  - [ ] Subtask 1.1: Tracking number input form with carrier selection
  - [ ] Subtask 1.2: Carrier API validation of tracking numbers
  - [ ] Subtask 1.3: Photo upload for shipping receipt/label
- [ ] Task 2: Automated tracking updates
  - [ ] Subtask 2.1: Webhook integration with major carriers
  - [ ] Subtask 2.2: Periodic polling for tracking status updates
  - [ ] Subtask 2.3: Order status mapping from tracking events
- [ ] Task 3: Notification and reminder system
  - [ ] Subtask 3.1: Immediate buyer notification with tracking info
  - [ ] Subtask 3.2: Maker reminder notifications for missing tracking
  - [ ] Subtask 3.3: Automated status update notifications

## Dev Notes
- Carrier APIs: USPS, FedEx, UPS tracking APIs
- Webhooks: Real-time tracking event notifications
- Database: order_tracking table with tracking_number, carrier, status
- Reminders: Scheduled job checking orders without tracking
```

## 13-3-delivery-confirmation-flow.md
```markdown
# Story 13.3: Delivery Confirmation Flow

## Status
**Status:** Ready for Dev

## Story
As a buyer, I want to confirm receipt of my order and provide feedback so that the transaction can be completed and the maker can be paid.

## Acceptance Criteria
- [ ] AC1: Buyer receives notification when package is delivered (carrier confirmation)
- [ ] AC2: Buyer can mark order as received within app
- [ ] AC3: Order auto-completes 7 days after delivery if no issues reported
- [ ] AC4: Buyer can report delivery issues before auto-completion
- [ ] AC5: Maker receives notification when order is marked complete
- [ ] AC6: Payment is released to maker after completion confirmation

## Tasks
- [ ] Task 1: Delivery notification system
  - [ ] Subtask 1.1: Carrier delivery webhook processing
  - [ ] Subtask 1.2: Buyer notification with delivery confirmation prompt
  - [ ] Subtask 1.3: In-app delivery confirmation interface
- [ ] Task 2: Auto-completion workflow
  - [ ] Subtask 2.1: 7-day timer after delivery confirmation
  - [ ] Subtask 2.2: Auto-completion job with maker notification
  - [ ] Subtask 2.3: Payment release trigger to Stripe Connect
- [ ] Task 3: Issue reporting system
  - [ ] Subtask 3.1: "Report Issue" option before auto-completion
  - [ ] Subtask 3.2: Issue escalation to customer support
  - [ ] Subtask 3.3: Hold payment pending issue resolution

## Dev Notes
- Auto-completion: Scheduled job checking delivered orders
- Payment release: Stripe Connect transfer to maker account
- Issue tracking: Integration with customer support system
- Database: order completion timestamps, issue flags
```

## 13-4-shipping-issue-resolution.md
```markdown
# Story 13.4: Shipping Issue Resolution

## Status
**Status:** Ready for Dev

## Story
As a buyer or maker, I want to resolve shipping issues (lost packages, damage, delays) so that transactions can be completed fairly for both parties.

## Acceptance Criteria
- [ ] AC1: Buyer can report issues: not received, damaged, wrong item
- [ ] AC2: Maker can respond to issues with evidence/resolution offers
- [ ] AC3: Platform can mediate disputes with refund/replacement options
- [ ] AC4: Insurance claims can be filed for high-value lost/damaged items
- [ ] AC5: Resolution timeline is enforced (5 business days max)
- [ ] AC6: Maker rating is protected for legitimate shipping issues beyond their control

## Tasks
- [ ] Task 1: Issue reporting system
  - [ ] Subtask 1.1: Issue type selection and evidence upload
  - [ ] Subtask 1.2: Issue notification to maker and support team
  - [ ] Subtask 1.3: Issue tracking dashboard for all parties
- [ ] Task 2: Resolution workflow
  - [ ] Subtask 2.1: Maker response interface with evidence upload
  - [ ] Subtask 2.2: Platform mediation tools for support team
  - [ ] Subtask 2.3: Automated resolution options (refund, replacement)
- [ ] Task 3: Insurance and protection
  - [ ] Subtask 3.1: High-value item insurance integration
  - [ ] Subtask 3.2: Shipping insurance claim filing
  - [ ] Subtask 3.3: Maker protection for valid claims

## Dev Notes
- Issue types: not_received, damaged, wrong_item, quality_issue
- Evidence: Photo upload, tracking screenshots, correspondence
- Resolution: Full refund, partial refund, replacement, insurance claim
- Timeline: SLA enforcement with escalation triggers
```

**COPY THESE TEMPLATES INTO STORY FILES IMMEDIATELY**