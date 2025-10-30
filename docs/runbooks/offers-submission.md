# Runbook: Offers Submission Flow

## Purpose
Operational playbook for monitoring, troubleshooting, and recovering the Epic 9 offer submission pipeline, covering validation, payment/risk, auction trigger, cancellation, and audit workflows.

## Key Contacts
- **Primary On-Call**: Commerce Backend (PagerDuty service `Offers Submission`)
- **Secondary On-Call**: Commerce Platform (Slack `#eng-offers`)
- **Compliance Liaison**: audit@craft.video
- **Product Analytics**: analytics@craft.video

## Monitoring Checklist
- Datadog dashboards: `offers-submission-overview`, `offers-submission-slo`
- Kibana index: `offers-submission-*`
- Segment workspace: Offer funnel (draft → submitted → auction)
- EventBridge event bus: `commerce-offers-events@2025-09`
- Queue health: Redis replication group `offers-cache`

## Normal Operations
1. Validate dashboards are green at start of shift (success rate ≥98%, validation p95 <400ms).
2. Confirm nightly synthetic journey succeeded (validation → submission → cancellation).
3. Review Glacier export job summary email for completion status.
4. Ensure SNS notifications `offers-submitted` and `offers-cancelled` delivered (CloudWatch metrics).

## Incident Response

### Symptom: Submission Success Rate Drops <95%
1. Check Datadog metric `offers.submission.success_rate` for regression window.
2. Inspect Kibana logs for partner errors (`stripe_error`, `sift_error`, `plaid_error`).
3. If partner outage detected:
   - Activate feature flag `SOFT_LAUNCH_MODE` to limit traffic (if impact severe).
   - Notify vendor via support channel; document incident in `#eng-offers`.
   - Apply compensating logic if payment holds pending (run support script `scripts/offers/release_holds.dart`).
4. If application regression suspected:
   - Roll back to previous release or disable problematic feature flags.
   - Trigger `melos run test -- --tags offers` to validate fix candidates.
5. Record root cause and resolution in post-incident form.

### Symptom: Validation Latency >400ms p95
1. Verify OPA sidecar health (ECS metrics, `opa_offers_bundle` refresh status).
2. Confirm Redis latency; scale cluster if CPU >70%.
3. Review recent config changes in `offer_policy_repository` or maker policy updates.
4. If OPA bundle stale, redeploy pipeline to refresh `opa-offers-bundle@2025-10-15`.

### Symptom: Auction Trigger Lag >1000ms
1. Check EventBridge bus metrics for throttling.
2. Review `auction_trigger_service` logs for retries or dead-letter entries.
3. Validate downstream auction timer service availability (Epic 10 dependency).

### Symptom: High-Value Cancellation Spike
1. Inspect Kibana alert for cancellation reason distribution.
2. Confirm maker policy not misconfigured (auto reject threshold, SLA window).
3. Communicate with Maker Success team if legitimate business shift.

### Symptom: Audit Export Failure
1. PagerDuty alert will include Glacier job ID.
2. Check AWS Data Lifecycle Manager logs and IAM role permissions.
3. Retry export via support script `scripts/offers/run_glacier_export.dart`.
4. Notify compliance team; log actions in audit trail.

## Runbooks & Scripts
- `scripts/offers/release_holds.dart`: Releases payment holds when submissions fail mid-saga.
- `scripts/offers/run_glacier_export.dart`: Manually triggers audit export.
- `scripts/offers/requeue_events.dart`: Replays EventBridge events from DLQ.

## Configuration References
- Environment YAML: `docs/tech-spec-epic-9.md` §Environment Configuration.
- Feature flags: `OFFER_SUBMISSION_ENABLED`, `REAL_TIME_VALIDATION`, `SOFT_LAUNCH_MODE`.
- Secret management: Vault paths documented in tech spec.

## Escalation Policy
1. Tier 1 (Commerce Backend on-call) triages for up to 30 minutes.
2. Escalate to Tier 2 (Commerce Platform lead) if unresolved.
3. Notify Compliance for audit-impacting incidents within 1 hour.
4. File incident report within 24 hours; attach logs and metrics snapshots.

## Maintenance Tasks
- Weekly: Review Datadog monitors, adjust thresholds if necessary, confirm no stale OPA bundles.
- Monthly: Perform Tabletop exercise for partner outage scenario.
- Quarterly: Validate Glacier restore process end-to-end.

## Revision History
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-29 | v1.0    | Initial runbook for offer submission operations | GitHub Copilot AI |
