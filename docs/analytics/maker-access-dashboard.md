# Capability Enablement Dashboard Specification

## Purpose
Provide unified-account visibility into capability requests, verification throughput, payout activation, and device trust health so operations teams can keep publish, payment, and fulfillment flows unblocked.

## Data Sources
- **Metrics Warehouse**: `capability.requests.*`, `capability.unlocked.*`, `capability.blockers.*`, `device.trust.*`
- **Datadog Metrics**: `capability.api.latency`, `capability.api.errors`, `capability.blockers.active`
- **Serverpod Audit Stream**: `audit.capability`, `audit.verification`, `audit.device_trust`
- **Analytics Events**: `capability_request_submitted`, `publish_verification_completed`, `payout_activation_completed`, `device_trust_revoked`
- **Stripe/Persona Webhooks**: Aggregated success/failure payloads for payout onboarding and identity checks

## Panels & Metrics
1. **Capability Funnel**
   - Requests → in review → unlocked counts by capability (`publish`, `collect_payments`, `fulfill_orders`)
   - Auto-approval vs. manual review rate (target ≥85% auto for publish)
   - Median time-to-unlock per capability (SLO: publish <10m, payout <1h, fulfillment <2h)
   - Rate-limit violations and duplicate requests flagged as anomalies
2. **Blocker Diagnostics**
   - Top blocker codes (`identity_docs_missing`, `stripe_requirements_due`, `device_trust_low`)
   - Age distribution of active blockers (<1h, 1–24h, >24h)
   - Cache invalidation latency (target <5s) and retry success rate after blocker surfaced
3. **Verification Health**
   - Persona outcome mix (approved, rejected, pending) with rejection reasons
   - Stripe Express onboarding completion vs. abandonment funnel
   - Tax document submission success rate and average resubmissions
4. **Device Trust Monitoring**
   - New trusted devices per day and average trusted devices per user
   - Low-trust alerts and revocations (threshold breaches, jailbreak/root detections)
   - Capability downgrades triggered by device events with follow-through status
5. **Compliance Snapshot**
   - Users with active capabilities by geography and content volume
   - Audit event ingestion lag (ingest → warehouse) target <2 min
   - CSV export success rate for compliance reviews

## Alerts
- **Capability Request Backlog > 50 pending for 15 min** → Slack `#capability-ops`
- **Manual review queue > 10 for >30 min** → PagerDuty Capability Ops
- **Persona webhook failures ≥3 consecutive** → PagerDuty Compliance On-Call
- **Stripe onboarding failures >5 in 10 min** → PagerDuty Payments On-Call
- **Device trust downgrades >10 in 10 min** → Slack `#security-ops`
- **Blocker age >24h for ≥5 users** → Slack `#support-escalations`

## Ownership
- **Primary**: Capability Operations Lead
- **Secondary**: Compliance Program Manager
- **Engineering Support**: Identity & Payments squad for data anomalies

## Runbook
Refer to `docs/runbooks/maker-access.md` for incident remediation steps, manual overrides, and escalation paths.
