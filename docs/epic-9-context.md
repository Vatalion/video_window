# Epic 9 Context: Offer Submission

**Generated:** 2025-11-04  
**Epic ID:** 9  
**Epic Title:** Offer Submission  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Offer Validation:** Dual validation (client real-time + server atomic)
- **Business Rules:** Minimum offer amount, increment requirements, qualification checks
- **Auction Trigger:** First qualified offer automatically starts 72-hour auction
- **Cancellation:** Free withdrawal before first bid, limited after bidding starts
- **Audit Trail:** Complete offer lifecycle tracking with immutable event log

### Technology Stack
- Flutter: flutter_bloc 9.1.0, flutter_stripe 10.1.0 (payment validation), equatable 2.0.5, intl 0.19.0
- Serverpod: Offers Service with validation rules engine
- PostgreSQL: offers, maker_profiles, artifact_stories, audit_log tables
- Redis: Real-time validation cache, business rule configuration
- Analytics: Datadog metrics (offers.validation.duration_ms), Segment events

### Key Integration Points
- `packages/features/commerce/` - Offer submission UI and validation feedback
- `video_window_server/lib/src/endpoints/offers/` - Offers endpoints with validation
- Business rule engine: Configurable validation rules (minimum, increments)
- Auction service: Automatic trigger on first qualified offer

### Implementation Patterns
- **Real-time Validation:** Client validates on keystroke (debounced 300ms), shows instant feedback
- **Server Validation:** Atomic qualification checks on submission (idempotent)
- **Qualification Checks:** User capability verification, payment method validation, fraud screening
- **State Machine:** Draft → Submitted → Qualified → Auction Active → Won/Lost

### Story Dependencies
1. **9.1:** Offer entry UI & real-time validation (foundation)
2. **9.2:** Server validation & auction trigger (depends on 9.1)
3. **9.3:** Offer withdrawal & cancellation (depends on 9.1, 9.2)
4. **9.4:** Offer state management & audit trail (depends on all above)

### Success Criteria
- Client validation responds in <300ms
- 100% offers passing client validation also pass server validation
- Auction triggers immediately (<1s) on first qualified offer
- Audit trail captures all state transitions with timestamps
- Cancellation rules enforced correctly (free before bids, limited after)

**Reference:** See `docs/tech-spec-epic-9.md` for full specification
