# Stripe Payments Runbook

## Summary
Guides on-call engineers through handling checkout failures, payment window issues, retry backlogs, and receipt generation incidents for Epic 12.

## Service Overview
- **Checkout Flow:** `payment_checkout_endpoint.dart` creates Stripe Checkout Sessions, `stripe_checkout_webhook.dart` processes completions/failures.
- **Window Enforcement:** EventBridge schedule `payments-window-expire-${ENV}` invokes `payment_window_task.dart` every 5 minutes to expire overdue sessions.
- **Retry System:** SQS queue `payments-retry-${ENV}` feeds `payment_retry_worker.dart` for exponential backoff retries.
- **Receipts:** `receipt_generation_service.dart` renders PDFs stored in S3 bucket `craft-video-receipts-${ENV}` delivered via CloudFront.

## Quick Links
- Dashboard: `docs/analytics/stripe-payments-dashboard.md`
- PagerDuty Service: Payments Checkout
- Kibana: index pattern `payments-*`
- SQS Console: `payments-retry-${ENV}` queue depth
- CloudFront Logs: `payments-receipts-${ENV}` access logs
- Slack Channels: `#eng-commerce`, `#ops-oncall`

## Initial Triage Checklist
1. Confirm which alert fired (checkout success drop, retry backlog, receipt errors) via PagerDuty/Slack.
2. Inspect corresponding Datadog widgets (Checkout Health, Payment Window, Retry, Receipts).
3. Review recent logs in Kibana filtered by `payment_session_id` or `receipt_number`.
4. Assess customer impact (number of sessions affected, auction IDs) via Segment events or database queries.

## Common Scenarios
### A. Checkout Failures Spike
- **Symptoms:** Success rate <97%, Stripe webhook lag, error `payment_intent.payment_failed`.
- **Actions:**
  1. Verify Stripe status page and API latency.
  2. Inspect webhook logs for signature errors; requeue failed events if necessary.
  3. Validate `payment_checkout_endpoint.dart` idempotency key collisions; restart Serverpod worker if stuck.
  4. Coordinate with Product to notify impacted users if widespread.

### B. Payment Window Not Expiring
- **Symptoms:** Sessions remain pending past 24h, `payments.window.expired_count` flat.
- **Actions:**
  1. Check EventBridge schedule status; rerun Terraform module if disabled.
  2. Examine Redis keys `payment:window:{sessionId}` for stale TTL; run reconciliation command `paymentWindow:reconcile`.
  3. Execute admin override via `payment_window_endpoint.dart` for critical auctions.

### C. Retry Backlog Growing
- **Symptoms:** SQS queue depth rising, retries failing repeatedly.
- **Actions:**
  1. Inspect `payment_retry_worker.dart` logs for Stripe API errors or permission issues.
  2. Increase worker concurrency temporarily using deployment pipeline.
  3. Move oldest messages to dead-letter queue after verifying customer contact plan.
  4. File incident if backlog >200 messages for more than 30 minutes.

### D. Receipt Generation Failures
- **Symptoms:** `payments.receipt.error_count` >0, download URLs returning 403.
- **Actions:**
  1. Review `receipt_generation_service.dart` logs for template errors; redeploy template if corrupted.
  2. Validate S3 bucket KMS permissions; rotate key if AWS errors `AccessDenied`.
  3. Re-trigger receipt generation via admin command `receipt:regenerate <receipt_id>`.
  4. Communicate with Support to resend receipts after fix.

## Escalation Paths
- **Level 1:** Commerce Backend (payments specialist on-call).
- **Level 2:** Infrastructure/SRE (for EventBridge, SQS, CloudFront issues).
- **Level 3:** Finance & Compliance (if receipts incorrect or PCI alerts triggered).

## Post-Incident Checklist
- Document incident in `Payments Incidents` Confluence page.
- Update `docs/analytics/stripe-payments-dashboard.md` if new widgets or alerts needed.
- Add retrospective notes to `docs/tech-spec-epic-12.md` change log when scope adjustments occur.
- Ensure Support Dossier updated with customer-facing messaging.

## Verification Steps
- Checkout success rate ≥97% over last 30 minutes.
- Payment window expirations processing (no session pending beyond 24h).
- Retry queue depth <10 messages with success rate trending upward.
- Receipt generation errors cleared and sample download verified.
- Segment events align with counts observed in Datadog.

## Contacts
- Commerce Backend Lead: TBD (update quarterly).
- Payments SRE Primary: via PagerDuty schedule `Payments Platform`.
- Finance Liaison: `finance@craftvideo.market`.
