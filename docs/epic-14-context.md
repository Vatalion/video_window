# Epic 14 Context: Dispute Resolution

**Generated:** 2025-11-04  
**Epic ID:** 14  
**Epic Title:** Dispute Resolution  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Issue Reporting Window:** 48-hour post-delivery period for buyer disputes
- **Dispute State Machine:** Open → Under Review → Awaiting Response → Resolved/Escalated
- **Evidence Collection:** Photo/text uploads with S3 storage (encrypted)
- **Refund Processing:** Stripe refund API with atomic ledger reconciliation
- **SLA Enforcement:** Response deadlines with automatic escalation triggers

### Technology Stack
- Flutter 3.19.6: Issue reporting UI, dispute management
- Serverpod 2.9.2: Dispute workflow orchestration, refund processing
- PostgreSQL 15: disputes, dispute_evidence, refund_transactions tables
- Stripe API: Refund execution via stripe 8.0.0 SDK
- AWS S3: Evidence storage with KMS encryption

### Key Integration Points
- `packages/features/commerce/` - Dispute reporting and tracking UI
- `video_window_server/lib/src/endpoints/disputes/` - Dispute lifecycle endpoints
- Stripe API: Refund creation and tracking
- Notification service: Dispute status updates for all parties

### Implementation Patterns
- **Issue Reporting:** Reason code selection + evidence upload + description
- **State Machine:** Automated transitions based on SLA timers and agent actions
- **Refund Processing:** Stripe refund API call → Ledger update (atomic transaction)
- **Admin Dashboard:** Support agent queue with dispute priority and SLA tracking

### Story Dependencies
1. **14.1:** Issue reporting UI (foundation)
2. **14.2:** Dispute workflow management (depends on 14.1)
3. **14.3:** Refund processing & settlement (depends on 14.1, 14.2)

### Success Criteria
- Issues reported within 48-hour window tracked 100%
- Disputes resolved within SLA (72 hours for standard, 24h for high-priority)
- Refunds processed in <24 hours from approval
- Admin dashboard operational for support agents
- Ledger reconciliation maintains consistency

**Reference:** See `docs/tech-spec-epic-14.md` for full specification
