# Epic 2: Capability Enablement & Verification – Technical Specification

**Epic Goal:** Progressively unlock publish, payment, and fulfillment capabilities for any authenticated user while keeping the default account frictionless.

**Stories:**
- 2.1 Capability Enablement Request Flow
- 2.2 Verification within Publish Flow
- 2.3 Payout & Compliance Activation
- 2.4 Device Trust & Risk Monitoring

## 1. Architecture Overview

### 1.1 Component Mapping
- **Flutter App**
  - Capability Center (settings → capabilities panel, in-flow prompts)
  - Publish flow, Checkout launcher, Fulfillment workspace (emit capability requests)
- **Serverpod**
  - Capability Service: orchestrates capability state machine, prerequisites, reviewer actions
  - Verification Service: integrates identity checks (Persona), payout onboarding (Stripe Express), compliance storage
  - Device Trust Service: stores device telemetry and risk decisions
- **Database**
  - `user_capabilities` table (snapshot flags + metadata)
  - `capability_requests` table (request lifecycle)
  - `verification_tasks` table (identity/doc upload, payout onboarding)
  - `trusted_devices` table (device fingerprint, trust score)
- **External Services**
  - Persona Connect (identity verification)
  - Stripe Connect Express (payout onboarding)
  - Risk engine (Apple/Google attestation, jailbroken/root detection libraries)

### 1.2 Capability Lifecycle
1. User attempts restricted action (publish, accept payment, fulfill order).
2. Client queries `GET /capabilities/status` to determine prerequisites.
3. If capability inactive, client opens guided checklist (Story 2.1) and posts `POST /capabilities/request`.
4. Server creates `capability_requests` record, kicks off verification tasks as required.
5. Once prerequisites satisfied (automatic or reviewer approval), Capability Service toggles flags in `user_capabilities` and emits event `capability.unlocked`.
6. Downstream services (publish flow, checkout, fulfillment) subscribe to capability events to unblock UI.

### 1.3 Capability Definitions
| Capability | Unlock Trigger | Prerequisites | Blocks Until Active |
| --- | --- | --- | --- |
| `can_publish` | Story publish attempt | Profile completeness, identity verification, policy attestation | Draft submission beyond preview |
| `can_collect_payments` | Buyer sent to checkout | Stripe Express onboarding, tax info, risk pass | Initiating checkout session |
| `can_fulfill_orders` | Adding tracking / fulfilling order | Shipping template, trusted device, payment capability active | Editing fulfillment data |

## 2. Data Models

```dart
class UserCapabilities {
  final String userId;
  final bool canPublish;
  final bool canCollectPayments;
  final bool canFulfillOrders;
  final DateTime? identityVerifiedAt;
  final DateTime? payoutConfiguredAt;
  final DateTime? fulfillmentEnabledAt;
  final CapabilityReviewState reviewState;
  final Map<String, String> blockers; // capability -> message
}

enum CapabilityReviewState { none, pending, manualReview }

class CapabilityRequest {
  final String id;
  final String userId;
  final CapabilityType capability;
  final CapabilityRequestStatus status;
  final Map<String, dynamic> metadata; // e.g., attestation result, reviewer notes
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
}

enum CapabilityType { publish, collectPayments, fulfillOrders }
enum CapabilityRequestStatus { requested, inReview, approved, blocked }

class VerificationTask {
  final String id;
  final String userId;
  final CapabilityType capability;
  final VerificationTaskType type; // persona_identity, stripe_payout, compliance_doc
  final VerificationTaskStatus status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
}

class TrustedDevice {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceType;
  final String platform;
  final double trustScore;
  final Map<String, dynamic> telemetry;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime? revokedAt;
}
```

## 3. API Endpoints

| Endpoint | Method | Description |
| --- | --- | --- |
| `/capabilities/status` | GET | Returns `UserCapabilities` snapshot along with active blockers |
| `/capabilities/request` | POST | Submits or refreshes a request for a capability; idempotent |
| `/capabilities/tasks/{id}` | GET | Returns status of a verification task |
| `/capabilities/tasks/{id}/complete` | POST | Webhook/internal completion callback (Persona, Stripe) |
| `/capabilities/admin/requests` | GET | Reviewer queue for manual approvals |
| `/capabilities/admin/requests/{id}/decision` | POST | Reviewer approval/denial with notes |
| `/devices/register` | POST | Registers/updates trusted device telemetry |
| `/devices` | GET | Lists active devices for the current user |
| `/devices/{id}/revoke` | POST | Allows user or admin to revoke device trust |

### 3.1 Request Payload Examples

```dart
// POST /capabilities/request
{
  "capability": "publish",
  "context": {
    "entryPoint": "story_editor",
    "draftId": "uuid"
  }
}

// Persona webhook → POST /capabilities/tasks/{id}/complete
{
  "status": "approved",
  "provider": "persona",
  "metadata": {
    "verificationId": "ver_123",
    "reason": null
  }
}
```

## 4. Implementation Details (Story Mapping)

### Story 2.1 Capability Enablement Request Flow
- Flutter capability center module located at `packages/features/profile/lib/presentation/capability_center/`.
- `CapabilityCenterBloc` orchestrates load status, capability toggle states, and CTA handling.
- Use `CapabilityRepository` (core package) to call `/capabilities/status` (GET) at app start and when restricted actions triggered.
- UI states: `inactive`, `inProgress`, `awaitingReview`, `ready`, `blocked` with call-to-action chips.
- Analytics event `capability_request_submitted` emitted with capability type and source.

### Story 2.2 Verification within Publish Flow
- Publish flow intercepts when `!user.capabilities.canPublish` and shows inline card summarizing requirements.
- Identity verification integrated via Persona hosted flow. Flutter uses `persona_flutter` (webview) to collect documents.
- Persona webhook hits `/capabilities/tasks/{id}/complete`, updating status and flipping `identityVerifiedAt` on success.
- Editor polls capability status; once `canPublish` true, publish CTA unblocks without re-auth.

### Story 2.3 Payout & Compliance Activation
- Checkout CTA checks `canCollectPayments`; if false, shows bottom sheet with Stripe Express onboarding deep link.
- Stripe onboarding success webhook attaches account ID to user record, sets `payoutConfiguredAt`, and resolves open requests.
- Tax info captured using Stripe tax forms API; stored encrypted within `verification_tasks.payload`.
- Payment initiation pipeline verifies flag again server-side before creating Stripe Checkout session.

### Story 2.4 Device Trust & Risk Monitoring
- Device registration invoked on app launch using `package_info_plus` and platform-specific risk SDKs.
- Trust score calculation: base 0.8 minus penalties for root/jailbreak, outdated OS, unsupported attestation; threshold configurable (`capability.minDeviceTrust`).
- If trust < threshold, Capability Service marks capability as `review_required` and emits notification to user.
- Device management screen lists devices with trust score; revocation triggers `/devices/{id}/revoke` and resets capability if no trusted devices remain.

## 5. Security & Compliance Considerations
- Capability toggles audited in `audit.capability_events` stream with before/after snapshot.
- Enforce idempotency via natural key `(user_id, capability)` on `capability_requests`.
- Store verification documents encrypted at rest using CMK `alias/video-window-sensitive-docs`.
- Validate Persona webhook signatures and handle retries.
- Stripe account IDs and verification status stored encrypted; redacted from logs.
- Device telemetry redacted before logging; trust score calculation deterministic for reproducibility.

## 6. Database Schema

```sql
CREATE TABLE user_capabilities (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  can_publish BOOLEAN DEFAULT false,
  can_collect_payments BOOLEAN DEFAULT false,
  can_fulfill_orders BOOLEAN DEFAULT false,
  identity_verified_at TIMESTAMPTZ,
  payout_configured_at TIMESTAMPTZ,
  fulfillment_enabled_at TIMESTAMPTZ,
  review_state VARCHAR(32) DEFAULT 'none',
  blockers JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE capability_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  capability VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  UNIQUE(user_id, capability)
);

CREATE TABLE verification_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  capability VARCHAR(32) NOT NULL,
  task_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE trusted_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id VARCHAR(255) NOT NULL,
  device_type VARCHAR(100) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  trust_score NUMERIC(5,2) NOT NULL,
  telemetry JSONB,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  UNIQUE(user_id, device_id)
);

CREATE INDEX idx_capability_requests_status ON capability_requests(status);
CREATE INDEX idx_verification_tasks_status ON verification_tasks(status);
CREATE INDEX idx_trusted_devices_user_id ON trusted_devices(user_id);
```

## 7. Source Tree & File Directives

| Path | Action | Story | Notes |
| --- | --- | --- | --- |
| `video_window_flutter/packages/core/lib/data/repositories/capability_repository.dart` | create | 2.1 | Fetch/update capability status |
| `video_window_flutter/packages/features/profile/lib/presentation/capability_center/` | create | 2.1 | UI + bloc for capability management |
| `video_window_flutter/packages/features/story_editor/lib/presentation/widgets/publish_capability_card.dart` | create | 2.2 | Inline prompt in publish flow |
| `video_window_flutter/packages/features/checkout/lib/presentation/widgets/payout_blocker_sheet.dart` | create | 2.3 | UI for payment capability blockers |
| `video_window_flutter/packages/features/orders/lib/presentation/widgets/fulfillment_capability_callout.dart` | create | 2.4 | Inline messaging in fulfillment tools |
| `video_window_flutter/packages/core/lib/data/services/capabilities/capability_service.dart` | create | 2.1-2.4 | API client + polling helpers |
| `video_window_server/lib/src/endpoints/capabilities/capability_endpoint.dart` | create | 2.1 | REST endpoints |
| `video_window_server/lib/src/services/capability_service.dart` | create | 2.1 | State machine + blockers |
| `video_window_server/lib/src/services/verification_service.dart` | create | 2.2-2.3 | Persona, Stripe orchestration |
| `video_window_server/lib/src/services/device_trust_service.dart` | create | 2.4 | Device telemetry + scoring |
| `video_window_server/lib/src/repositories/capability_repository.dart` | create | all | Persistence helpers |
| `video_window_server/migrations/2025-11-02T00-capability-model.sql` | create | all | Combined migration defined above |
| `video_window_flutter/packages/features/profile/test/presentation/capability_center_bloc_test.dart` | create | 2.1 | Bloc unit tests |
| `video_window_server/test/services/capability_service_test.dart` | create | 2.1 | State machine tests |
| `video_window_server/test/services/device_trust_service_test.dart` | create | 2.4 | Risk scoring tests |

## 8. Implementation Guide

1. **Bootstrap Capability Service (Story 2.1)**
   - Implement schema + repositories.
   - Expose capability status/request endpoints with idempotency and audit events.
   - Build Flutter capability center and inline prompts with instrumentation.
2. **Inline Publish Verification (Story 2.2)**
   - Integrate Persona hosted flow + webhook.
   - Update capability service to auto-approve `can_publish` when identity verified.
3. **Payout Activation (Story 2.3)**
   - Implement Stripe Express onboarding handshake; store account IDs securely.
   - Guard checkout initiation on `can_collect_payments` server-side.
4. **Device Trust (Story 2.4)**
   - Implement device telemetry capture, scoring, revocation UI, and capability downgrade triggers.
5. **Observability & Governance**
   - Emit `capability.requested`, `capability.approved`, `capability.blocked` events.
   - Dashboards for unlock funnel, blocker distribution, device anomalies.

## 9. Acceptance Criteria Traceability

| Acceptance Criterion | Implementation Artifact | Test Coverage |
| --- | --- | --- |
| Story 2.1 AC1 | Capability center UI, inline prompts | Widget + bloc tests |
| Story 2.1 AC2 | `/capabilities/request`, `capability_service.dart` | `capability_service_test.dart` |
| Story 2.1 AC3 | Audit events on unlock | Integration test `capability_unlock_flow_test.dart` |
| Story 2.2 AC1 | Publish wizard updates | `publish_capability_flow_test.dart` |
| Story 2.2 AC2 | Persona integration | `verification_service_test.dart`, sandbox dry run |
| Story 2.3 AC1 | Stripe onboarding flow | `payout_activation_integration_test.dart` |
| Story 2.3 AC2 | Checkout guard | `checkout_capability_guard_test.dart` |
| Story 2.4 AC1 | Device telemetry capture | `device_trust_service_test.dart` |
| Story 2.4 AC3 | Device management UI | Widget + bloc tests |

## 10. Testing Strategy

- **Unit**: capability service, device trust scoring, capability center bloc.
- **Integration**: Persona sandbox, Stripe Express onboarding, checkout guard.
- **Security**: attempt capability bypass, replay webhooks, device spoofing.
- **Performance**: capability status p95 < 50ms; no duplicate requests under load.

## 11. Monitoring & Analytics

- Dashboards: capability funnel, average unlock time, blocker distribution, device trust anomalies.
- Alerts: burst of blocked requests (>5 in 10m), webhook failures, multiple low trust devices per user.

## 12. Deployment Considerations

- Feature flag `capability_center.enabled` for staged rollout.
- Backfill job migrating approved makers to new capability flags.
- Update runbooks with troubleshooting steps and manual override tooling.

## 13. Success Criteria

- ≥90% of publish capability requests auto-approved within 10 minutes.
- ≥80% payout onboarding completion for users who start the flow.
- Device trust false-positive rate ≤2% (resolved within SLA).
- No increase in fraudulent listings/payments post rollout (weekly monitoring).

## 14. Open Questions

1. Manual review capacity for blocked requests during pilot?
2. Future support for partial capability unlock (e.g., digital-only items)?
3. Need for historical capability snapshots beyond audit events?
