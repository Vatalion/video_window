# Epic 13 Context: Shipping & Fulfillment

**Generated:** 2025-11-04  
**Epic ID:** 13  
**Epic Title:** Shipping & Fulfillment  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Address Validation:** EasyPost API v2 for real-time validation and normalization
- **Carrier Integration:** Multi-carrier support via EasyPost (USPS, UPS, FedEx, DHL)
- **SLA Enforcement:** 72-hour tracking upload deadline with automated reminders
- **Status Visibility:** Real-time tracking updates for buyers and makers
- **Notification Integration:** Status change alerts via notification service (Epic 11)

### Technology Stack
- Flutter 3.19.6: Shipping address forms, tracking status UI
- Serverpod 2.9.2: Order management, carrier integration endpoints
- EasyPost API v2: Address validation, tracking webhooks
- PostgreSQL 15: orders, shipping_addresses, tracking_info tables
- Redis 7.2.4: SLA timer tracking and countdown state

### Key Integration Points
- `packages/features/commerce/` - Shipping forms and tracking UI
- `video_window_server/lib/src/endpoints/orders/` - Order and shipping endpoints
- EasyPost API: Address validation and multi-carrier tracking
- Notification service: Shipping status change alerts

### Implementation Patterns
- **Address Collection:** Form with real-time validation (<2s response via EasyPost)
- **Carrier Integration:** Automatic carrier detection, webhook-based tracking updates
- **SLA Tracking:** 72-hour countdown from payment success, escalating reminders (48h, 24h, 6h)
- **Status Synchronization:** Webhook from EasyPost → Database update → Notification push

### Story Dependencies
1. **13.1:** Shipping address collection & validation (foundation)
2. **13.2:** Tracking number management & carrier integration (depends on 13.1)
3. **13.3:** Shipping SLA timers & reminders (depends on 13.1, 13.2)
4. **13.4:** Order status visibility & notifications (depends on all above)

### Success Criteria
- Address validation completes in <2 seconds
- Tracking updates propagate in <1 minute from carrier event
- SLA reminders prevent 95%+ of deadline violations
- Status visibility for all stakeholders (buyer, maker, support)
- Multi-carrier support (USPS, UPS, FedEx, DHL)

**Reference:** See `docs/tech-spec-epic-13.md` for full specification
