# Maker Access Incident Runbook

## Scope
Guides response to incidents involving maker invitations, RBAC assignments, KYC workflows, and device trust enforcement.

## Contacts
- **Primary On-Call**: Maker Access Team (`maker-access` PagerDuty)
- **Secondary**: Compliance Operations (`compliance-ops` Slack)
- **Security Liaison**: Security Operations (SOC)

## Common Scenarios
1. **Invitation Creation Failures**
   - Check Datadog panel "Invitation Failure Rate".
   - Validate SendGrid/Twilio operational status.
   - Inspect Serverpod logs for HMAC or rate-limit errors (logger `maker.invitation`).
   - If Redis unavailable, fail over to replica using `melos run infra:redis-failover`.
2. **RBAC Privilege Escalation Alert**
   - Review `audit.rbac` event details for actor and diff payload.
   - If unauthorized, immediately remove roles via admin UI or `serverpod rbac:revoke --user <id>`.
   - Notify Security Ops and create incident ticket.
3. **Persona Webhook Failures**
   - Confirm webhook signature validation errors in logs.
   - Re-run Persona delivery via dashboard; if repeated, rotate webhook secret (`persona webhook rotate`).
   - Update maker status manually if decision confirmed.
4. **Device Trust Degradation**
   - Monitor `maker.device` metrics for high-risk devices.
   - Force logout suspicious devices via `serverpod device:disable --device <id>`.
   - Communicate with maker for re-verification if needed.

## Manual Operations
- **Resend Invitation**: `serverpod invitation:resend --invitation <id>`
- **Force RBAC Cache Clear**: `serverpod rbac:invalidate-cache`
- **Trigger Persona Sync**: `serverpod kyc:resync --profile <id>`
- **Export Compliance Snapshot**: `serverpod compliance:export --format csv`

## Post-Incident Tasks
1. Summarize incident in PagerDuty with root cause and remediation.
2. Update Maker Access dashboard with annotation including impact window.
3. File Jira follow-up for code/config fixes.
4. Ensure audit trail has complete sequence of actions for compliance review.

## Reference Material
- `docs/tech-spec-epic-2.md`
- `docs/analytics/maker-access-dashboard.md`
- Persona status page & webhook documentation
