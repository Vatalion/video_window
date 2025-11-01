# Tech Spec: Epic 14 - Issue Resolution & Refund Handling

**Epic ID:** 14  
**Epic Title:** Issue Resolution & Refund Handling  
**Created:** 2025-10-31  
**Status:** Draft  
**Priority:** Operations (Sprint 9-11)

---

## Overview

Enable structured issue reporting, dispute resolution workflows, and automated refund processing for marketplace transactions.

### Business Goals
- Provide buyers with clear issue reporting mechanism within 48-hour window
- Enable support agents to manage disputes efficiently with defined workflow states
- Automate refund processing with Stripe integration and ledger reconciliation

### Dependencies
- **Epic 12:** Checkout & Payment (Stripe integration, payment records)
- **Epic 13:** Shipping & Fulfillment (order status, delivery confirmation)
- **Epic 11:** Notifications (dispute alerts, resolution communications)

---

## Architecture

### Component Structure
```
Issue Resolution System
├── Issue Reporting (Client)
│   ├── Issue button (48h window post-delivery)
│   ├── Reason codes (wrong item, damaged, not as described, other)
│   ├── Evidence upload (photos, text)
│   └── Confirmation flow
├── Dispute Workflow (Backend)
│   ├── Dispute state machine (Open, Under Review, Awaiting Response, Resolved, Escalated)
│   ├── SLA tracking (response deadlines, escalation triggers)
│   └── Support dashboard API
└── Refund Processing (Backend)
    ├── Stripe refund API integration
    ├── Ledger reconciliation
    ├── Partial refund calculation
    └── Notification triggers
```

### Database Schema

**disputes table:**
```sql
CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id),
  buyer_id UUID NOT NULL REFERENCES users(id),
  maker_id UUID NOT NULL REFERENCES users(id),
  reason_code VARCHAR(50) NOT NULL, -- wrong_item, damaged, not_as_described, other
  description TEXT NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, under_review, awaiting_response, resolved, escalated
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolution_type VARCHAR(50), -- full_refund, partial_refund, no_action, replacement
  refund_amount_cents INT,
  assigned_agent_id UUID REFERENCES admin_users(id),
  escalated_reason TEXT,
  CONSTRAINT valid_status CHECK (status IN ('open', 'under_review', 'awaiting_response', 'resolved', 'escalated'))
);

CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_order_id ON disputes(order_id);
CREATE INDEX idx_disputes_created_at ON disputes(created_at DESC);
```

**dispute_evidence table:**
```sql
CREATE TABLE dispute_evidence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  evidence_type VARCHAR(50) NOT NULL, -- photo, text, shipping_label
  s3_key VARCHAR(512), -- for photos/documents
  text_content TEXT, -- for text evidence
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dispute_evidence_dispute_id ON dispute_evidence(dispute_id);
```

**dispute_timeline table:**
```sql
CREATE TABLE dispute_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL, -- created, status_changed, evidence_added, message_sent, resolved
  actor_id UUID NOT NULL REFERENCES users(id),
  actor_type VARCHAR(20) NOT NULL, -- buyer, maker, admin
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dispute_timeline_dispute_id ON dispute_timeline(dispute_id);
CREATE INDEX idx_dispute_timeline_created_at ON dispute_timeline(created_at DESC);
```

**refunds table:**
```sql
CREATE TABLE refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id),
  dispute_id UUID REFERENCES disputes(id),
  stripe_refund_id VARCHAR(255) UNIQUE NOT NULL,
  amount_cents INT NOT NULL,
  marketplace_fee_refund_cents INT NOT NULL,
  reason VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, succeeded, failed, cancelled
  initiated_by UUID NOT NULL REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX idx_refunds_order_id ON refunds(order_id);
CREATE INDEX idx_refunds_stripe_refund_id ON refunds(stripe_refund_id);
```

---

## Implementation Guide

### Story 14.1: Enable Issue Reporting

**Client Implementation:**
1. Add "Report Issue" button on order detail page
   - Visible only if: `order.status === 'delivered'` AND `NOW() - order.delivered_at <= 48 hours`
2. Create issue reporting form:
   ```dart
   class IssueReportingPage extends StatefulWidget {
     final Order order;
   }
   
   // Fields:
   // - Reason code dropdown (required)
   // - Description textarea (required, 50-500 chars)
   // - Photo upload (optional, up to 3 images)
   ```
3. Submit to `POST /api/disputes` endpoint
4. Show confirmation with dispute ID and next steps

**Backend Implementation:**
1. Create Serverpod endpoint: `DisputeEndpoint.createDispute()`
2. Validation:
   - Verify buyer owns order
   - Check 48-hour window: `ORDER.delivered_at + INTERVAL '48 hours' > NOW()`
   - Validate reason code
   - Limit description 50-500 characters
3. Create dispute record with status='open'
4. Upload evidence to S3 (if photos provided)
5. Insert dispute_timeline entry (event_type='created')
6. Send notifications to buyer (confirmation) and maker (alert)
7. Return dispute ID and SLA info

**Testing:**
- Unit: Validation logic (48h window, field limits)
- Integration: Full dispute creation flow
- E2E: Submit issue report, verify notifications sent

---

### Story 14.2: Manage Dispute Workflow

**Backend Implementation:**
1. Create Support Dashboard API endpoint: `DisputeEndpoint.getDisputeQueue()`
   ```dart
   class DisputeQueueRequest {
     String? status; // filter
     String? severity; // filter
     int page;
     int pageSize;
   }
   ```
2. Implement dispute state machine:
   ```dart
   enum DisputeStatus {
     open,
     underReview,
     awaitingResponse,
     resolved,
     escalated
   }
   
   class DisputeStateMachine {
     static bool canTransition(DisputeStatus from, DisputeStatus to) {
       // Define valid transitions
     }
   }
   ```
3. SLA tracking:
   - Open → Under Review: 24 hours
   - Under Review → Awaiting Response: 48 hours
   - Awaiting Response → Resolved: 72 hours
   - Auto-escalate if SLA exceeded
4. Add admin actions:
   - `updateDisputeStatus()`
   - `requestAdditionalInfo()`
   - `escalateDispute()`

**Admin Dashboard (Flutter Web):**
1. Dispute queue table with filters
2. Dispute detail view with timeline
3. Action buttons (request info, escalate, resolve)
4. Evidence viewer (photos, text)

**Testing:**
- Unit: State machine transitions
- Integration: SLA auto-escalation
- E2E: Admin workflow from queue to resolution

---

### Story 14.3: Execute Refunds and Settlement Actions

**Backend Implementation:**
1. Create `RefundService`:
   ```dart
   class RefundService {
     Future<Refund> processFullRefund(Order order, Dispute dispute);
     Future<Refund> processPartialRefund(Order order, int amountCents);
     Future<void> reconcileLedger(Refund refund);
   }
   ```
2. Stripe integration:
   ```dart
   // Full refund
   final refund = await stripe.refunds.create(
     payment_intent: order.stripePaymentIntentId,
     reason: 'requested_by_customer',
   );
   
   // Partial refund
   final refund = await stripe.refunds.create(
     payment_intent: order.stripePaymentIntentId,
     amount: amountCents,
   );
   ```
3. Marketplace fee calculation:
   ```dart
   // Full refund: refund full marketplace fee
   // Partial refund: pro-rate fee
   final feeRefund = (refundAmount / order.totalAmount) * order.marketplaceFee;
   ```
4. Ledger reconciliation:
   - Update `order.status = 'refunded'` or `'partially_refunded'`
   - Create ledger entry (negative amount)
   - Adjust maker payout (if not yet transferred)
5. Notifications:
   - Buyer: "Refund processed - $X.XX will appear in 5-10 business days"
   - Maker: "Refund issued for order #123 - your earnings adjusted"
6. Close dispute: `dispute.status = 'resolved'`, `resolution_type = 'full_refund'`

**Testing:**
- Unit: Fee calculation, ledger updates
- Integration: Stripe refund API (test mode)
- E2E: Full refund flow with notification verification

---

## API Endpoints

### Create Dispute
```
POST /api/disputes
Headers: Authorization: Bearer {token}
Body: {
  "orderId": "uuid",
  "reasonCode": "damaged",
  "description": "string",
  "evidence": ["base64-encoded-images"]
}
Response: {
  "disputeId": "uuid",
  "status": "open",
  "nextSteps": "string",
  "responseSla": "2025-11-02T10:00:00Z"
}
```

### Get Dispute Queue (Admin)
```
GET /api/admin/disputes?status=open&page=1&pageSize=20
Headers: Authorization: Bearer {admin-token}
Response: {
  "disputes": [DisputeQueueItem],
  "total": 42,
  "page": 1
}
```

### Update Dispute Status (Admin)
```
PATCH /api/admin/disputes/{id}/status
Body: {
  "status": "under_review",
  "message": "Reviewing evidence..."
}
```

### Process Refund (Admin)
```
POST /api/admin/disputes/{id}/refund
Body: {
  "refundType": "full" | "partial",
  "amountCents": 5000, // for partial
  "reason": "string"
}
Response: {
  "refundId": "uuid",
  "stripeRefundId": "re_xxx",
  "status": "succeeded"
}
```

---

## Testing Strategy

### Unit Tests
- Dispute validation (48h window, field limits)
- State machine transitions
- Refund amount calculations
- Ledger reconciliation logic

### Integration Tests
- Full dispute creation flow
- SLA auto-escalation
- Stripe refund API (test mode)
- Notification delivery

### E2E Tests
- Buyer reports issue → Admin reviews → Refund processed → Notifications sent

### Performance Tests
- Support dashboard load time with 1000+ disputes
- Evidence upload performance (3x 5MB images)

---

## Security Considerations

1. **Evidence Storage:** Secure S3 bucket with signed URLs (24h expiry)
2. **Admin Access:** SSO + MFA required for admin portal
3. **Refund Authorization:** Require admin approval for refunds >$500
4. **Audit Trail:** All dispute actions logged in `dispute_timeline`
5. **PII Protection:** Mask buyer/maker info in logs

---

## Compliance

- **GDPR:** Dispute data included in DSAR exports
- **Payment Card Industry (PCI):** No card data stored (Stripe handles)
- **Record Retention:** Disputes retained 7 years per financial regulations

---

## Success Metrics

- Issue reporting completion rate: >90%
- Dispute resolution SLA: <72 hours (80% of cases)
- Refund processing time: <24 hours
- Escalation rate: <10% of disputes

---

## Related Documents

- [PRD Epic 14](./prd.md#epic-14-issue-resolution--refund-handling)
- [Tech Spec Epic 12](./tech-spec-epic-12.md) - Payments
- [Tech Spec Epic 13](./tech-spec-epic-13.md) - Shipping
- [Definition of Ready](./process/definition-of-ready.md)

---

**Status:** Draft - Awaiting Validation  
**Next Steps:** Create user stories, run validation checklist  
**Owner:** Winston (Architect) + BMad Master
