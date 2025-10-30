# Authentication Dashboard Specification

## Purpose
Monitor the health and security posture of viewer and maker authentication flows across email OTP, social login, session refresh, and recovery.

## Data Sources
- **Datadog RUM/APM**: `auth.*` metrics emitted by mobile apps and Serverpod services.
- **Serverpod Audit Stream**: `audit.auth.*` events consumed via Kinesis → Snowflake for compliance reporting.
- **Segment Analytics**: Funnel events (`auth_otp_sent`, `auth_otp_verified`, `social_login_succeeded`, `auth_session_refreshed`, `auth_recovery_started`).

## Panels & Metrics
1. **Authentication Success Overview**
   - Login success rate by provider (email, Google, Apple)
   - OTP delivery latency (p50/p95)
   - OTP verification success vs. failure counts
2. **Session Health**
   - Refresh latency (p95 target ≤1s)
   - Refresh failure rate (<1%)
   - Token reuse detection count (stacked by platform)
3. **Recovery & Lockouts**
   - Recovery request volume vs. completions
   - Lockout events triggered by reuse/brute force attempts
   - Recovery token processing latency
4. **Security Alerts**
   - Rate limit violations per minute
   - Suspicious location/device combinations
   - Audit log ingestion health (lag < 30s)
5. **Funnel Visualization**
   - OTP → Authenticated conversion
   - Social login drop-off points (token rejected, linking failure, fallback usage)

## Alerts
- **Refresh Failure Rate > 2% (5 min)** → PagerDuty: Mobile Platform On-Call
- **Token Reuse Detection > 3 in 15 min** → PagerDuty: Security Incident Response
- **OTP Delivery Latency > 8s (p95)** → Email Provider Ops Channel

## Ownership
- **Primary**: Identity Squad – Engineering Manager
- **Secondary**: Security Operations (alert response)

## Runbook
Refer to `docs/runbooks/authentication.md` for alert response procedures and manual remediation steps.
