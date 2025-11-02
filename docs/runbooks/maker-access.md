# Capability Operations Incident Runbook

## Scope
Guides response to incidents involving capability requests, verification workflows (Persona, Stripe), payout activation, and device trust downgrades within the unified account model.

## Contacts
- **Primary On-Call**: Capability Operations PagerDuty (`capability-ops` schedule)
- **Secondary**: Compliance Operations (`#compliance-ops` Slack)
- **Security Liaison**: Security Operations Center (SOC)
- **Engineering Escalation**: Identity & Payments squad rotation

## Common Scenarios
1. **Capability Request Backlog**
   - Check Grafana panel “Capability Funnel”.
   - Inspect `capability_service` logs for queue saturation or audit publish failures.
   - If backlog tied to webhook delays, pause auto-approvals and notify compliance.
   - Escalate if backlog >50 requests for 15 minutes.
2. **Persona Webhook Failures**
   - Review `audit.verification` events for consecutive failures.
   - Validate webhook signature configuration; rotate secret if mismatch.
   - Manually approve in Persona dashboard when documentation verified; capture audit ID.
3. **Stripe Onboarding Blockers**
   - Monitor Blocker Diagnostics panel for `stripe_requirements_due` spikes.
   - Re-trigger requirements fetch via `serverpod capability:payout-refresh --user <id>`.
   - Escalate to Stripe support if requirements cannot be resolved within SLA.
4. **Device Trust Downgrades**
   - Review `device_trust_service` metrics for low-trust bursts.
   - Confirm attestation provider status (Apple DeviceCheck / Play Integrity).
   - If false positives suspected, adjust threshold via feature flag `capability.minDeviceTrust` after security sign-off.
   - Communicate with the user for re-verification if needed.

## Manual Operations
- **Force Capability Unlock**: `serverpod capability:unlock --user <id> --capability publish`
- **Re-run Verification Task**: `serverpod capability:retry-task --task <id>`
- **Trigger Device Reassessment**: `serverpod capability:rescore-device --device <id>`
- **Export Audit Snapshot**: `serverpod capability:audit-export --user <id> --format csv`

## Post-Incident Tasks
1. Document incident timeline in PagerDuty with root cause and remediation.
2. Annotate Capability Enablement dashboard with impact window and actions taken.
3. File Jira follow-up for automation or policy updates.
4. Review audit stream to ensure all manual overrides include correlation IDs.

## Reference Material
- `docs/tech-spec-epic-2.md`
- `docs/analytics/maker-access-dashboard.md`
- Persona status page & webhook documentation
- Stripe Connect Express operations guide
