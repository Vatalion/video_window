# Maker Access Dashboard Specification

## Purpose
Provide visibility into maker onboarding, RBAC changes, KYC processing, and device security posture.

## Data Sources
- **Datadog Metrics**: `maker.invitation.*`, `maker.rbac.*`, `maker.kyc.*`, `maker.device.*`
- **Serverpod Audit Stream**: `audit.invitation`, `audit.rbac`, `audit.kyc`
- **Segment Analytics**: Onboarding funnel events (`maker_invite_sent`, `maker_invite_claimed`, `maker_kyc_submitted`, `maker_device_registered`).

## Panels & Metrics
1. **Invitation Lifecycle**
   - Invitations created vs. claimed vs. expired
   - Claim success rate by role bundle
   - Rate limit violations and brute-force attempts
2. **RBAC Activity**
   - Role assignment volume (heatmap by actor)
  - Cache invalidation latency (target <5s)
   - Permission denial count by API endpoint
3. **KYC Processing**
   - Persona session statuses (pending, under_review, verified, rejected)
   - Average time from submission to decision (target <24h)
   - Document upload failure reasons (oversize, mime, encryption errors)
4. **Device Security**
   - New device registrations per day
   - High-risk device revocations
   - MFA/attestation failures
5. **Compliance Snapshot**
   - Makers by verification status
   - Audit log ingestion lag
   - CSV export success rate

## Alerts
- **Invitation Failures > 10/min** → Ops Slack `#maker-ops`
- **RBAC Changes > 5/10min by same actor** → Security Ops PagerDuty
- **Persona Webhook Failures > 3 consecutive** → Compliance On-Call
- **Device Revocation Spike (>5 in 10min)** → Maker Reliability On-Call

## Ownership
- **Primary**: Maker Access Team Lead
- **Secondary**: Compliance Program Manager

## Runbook
Refer to `docs/runbooks/maker-access.md` for incident remediation steps and manual overrides.
