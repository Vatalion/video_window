# Epic 12 Context: Payments

**Generated:** 2025-11-04  
**Epic ID:** 12  
**Epic Title:** Payments  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Payment Method:** Stripe Checkout (hosted, SAQ A PCI compliant)
- **Payment Window:** 24-hour deadline with countdown timer and enforcement
- **Retry Mechanism:** Limited retry attempts (3 max) with increasing delays
- **Receipts:** PDF generation with S3 storage (Object Lock), CloudFront signed URLs
- **Webhook-Driven:** Stripe webhooks drive state machine (idempotent processing)

### Technology Stack
- Flutter: flutter_stripe 10.1.0, webview_flutter 4.7.0, flutter_bloc 9.1.0, intl 0.19.0
- Serverpod: stripe 8.0.0 SDK, Payment Service endpoints
- Stripe: Checkout Sessions, Connect Express, webhook signature verification
- Storage: AWS S3 (receipts with Object Lock), CloudFront signed URLs (24h TTL)
- Scheduling: AWS EventBridge Scheduler for 24h window expiration
- Observability: Datadog (payments.*), Kibana, PagerDuty alerts

### Key Integration Points
- `packages/features/commerce/` - Payment checkout UI and status tracking
- `video_window_server/lib/src/endpoints/payments/` - Payment and webhook endpoints
- Stripe Checkout: Hosted payment pages (webview integration)
- AWS S3: Receipt storage with KMS envelope encryption

### Implementation Patterns
- **Checkout Flow:** Create session → Launch webview → Webhook callback → Status update
- **24h Window:** Server countdown with client sync, automatic expiration enforcement
- **Retry Logic:** Exponential backoff (1h, 6h, 18h) with limited attempts
- **Receipt Generation:** PDF creation with pdfx 2.6.0, KMS encryption, signed CloudFront URLs

### Story Dependencies
1. **12.1:** Stripe Checkout integration (foundation)
2. **12.2:** Payment window enforcement (depends on 12.1)
3. **12.3:** Payment retry mechanisms (depends on 12.1, 12.2)
4. **12.4:** Receipt generation & storage (depends on 12.1)

### Success Criteria
- Checkout session creation <2 seconds
- Payment window enforced with ±1 second precision
- Receipts generated within 5 seconds of payment success
- Retry mechanism recovers 30%+ of failed payments
- Webhook processing is 100% idempotent

**Reference:** See `docs/tech-spec-epic-12.md` for full specification
