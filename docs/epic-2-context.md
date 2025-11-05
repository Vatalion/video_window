# Epic 2 Context: Maker Onboarding & Verification

**Generated:** 2025-11-04  
**Epic ID:** 2  
**Epic Title:** Maker Onboarding & Verification  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Capability Model:** Progressive unlocking (publish, payment, fulfillment)
- **Verification:** Persona Connect for identity, Stripe Express for payouts
- **Device Trust:** Apple/Google attestation, jailbreak/root detection
- **State Machine:** Request → Verification → Approval → Capability enabled

### Technology Stack
- Serverpod: Capability Service, Verification Service, Device Trust Service
- PostgreSQL: user_capabilities, capability_requests, verification_tasks, trusted_devices
- External: Persona Connect (identity), Stripe Connect Express (payouts)
- Security: Device attestation, risk engine

### Key Integration Points
- `packages/features/auth/` - Capability Center UI
- `video_window_server/lib/src/endpoints/capability/` - Capability endpoints
- Persona Connect API for identity verification
- Stripe Connect Express for payout onboarding

### Implementation Patterns
- **Progressive Unlocking:** Capabilities unlock on-demand when needed
- **Verification Flow:** Request → Prerequisites → Verification → Approval
- **Device Trust:** Fingerprint + attestation + risk score
- **Compliance:** Automated prerequisite checks and approvals

### Story Dependencies
1. **2.1:** Capability request flow (foundation)
2. **2.2:** Verification within publish (depends on 2.1)
3. **2.3:** Payout activation (depends on 2.1, 2.2)
4. **2.4:** Device trust monitoring (parallel)

### Success Criteria
- Users can request capabilities through guided flow
- Identity verification completes in <10 minutes
- Payout activation completes in <15 minutes
- Device trust prevents compromised devices

**Reference:** See `docs/tech-spec-epic-2.md` for full specification
