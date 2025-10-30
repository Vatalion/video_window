# Authentication Incident Runbook

## Scope
Covers viewer/maker authentication incidents across email OTP, social login, session refresh, and account recovery flows.

## Contacts
- **Primary On-Call**: Identity Squad (PagerDuty schedule `identity-auth`)
- **Secondary**: Security Operations (`security-ops` channel)
- **Stakeholders**: Product Manager (Auth), Compliance Lead

## Common Scenarios
1. **OTP Delivery Failures**
   - Check Datadog panel "OTP Delivery Latency" on Authentication Dashboard.
   - Verify SendGrid health via status page.
   - Retry `sendOtp` request in staging to reproduce.
   - If provider outage confirmed, enable fallback SMS template (run `melos run trigger:sms-fallback`).
2. **Social Login Token Rejection**
   - Inspect Serverpod logs (`auth.social` logger) for signature errors.
   - Confirm Google/Apple public keys up-to-date; run `dart run tools/update_oauth_keys.dart` if stale.
   - Validate OAuth credentials in 1Password vault `video-window-auth`.
3. **Refresh Token Reuse Alert**
4. 
   - Alert triggered: check Redis set `auth:reuse:{userId}` for details.
   - Immediately call `POST /auth/admin/force-logout` for affected user.
   - Notify Security Ops to start incident ticket and investigate account compromise.
5. **Account Recovery Lockout**
   - Review audit log entry `auth.recovery.lockout` with correlation ID.
   - Confirm user identity via support ticket.
   - Manually clear lockout using `serverpod auth:clear-lockout --user <id>` if legitimate.

## Manual Operations
- **Force Token Rotation**: `serverpod auth:rotate-keys --env <env>`
- **Purge Token Blacklist Entry**: `serverpod auth:clear-blacklist --token-id <uuid>`
- **Rebuild Session Cache**: `melos run auth:rebuild-session-cache`

## Post-Incident Tasks
1. Document timeline and impact in PagerDuty incident.
2. File Jira task for long-term remediation if root cause is code/config bug.
3. Update Authentication Dashboard annotations with incident context.
4. Review analytics to confirm metrics returned to baseline.

## Reference Material
- `docs/tech-spec-epic-1.md`
- `docs/analytics/authentication-dashboard.md`
- SendGrid + Twilio status pages
