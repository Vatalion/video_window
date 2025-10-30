# Stripe Payments Dashboard

## Overview
Operational dashboard for monitoring Stripe Checkout sessions, payment retries, and receipt generation defined in Epic 12. Use during daily commerce stand-up and on-call incidents.

## Data Sources
- **Datadog Metrics:** `payments.checkout.sessions_active`, `payments.checkout.success_rate`, `payments.window.expired_count`, `payments.retry.attempt_count`, `payments.retry.success_rate`, `payments.receipt.render_time_ms`, `payments.receipt.error_count`.
- **Kibana Logs:** Index `payments-*` capturing webhook processing latency, retry worker actions, receipt generation logs.
- **Segment Events:** `payments.checkout.started`, `payments.checkout.completed`, `payments.checkout.expired`, `payments.retry.initiated`, `payments.retry.completed`, `payments.receipt.generated`.
- **AWS:** EventBridge execution logs, SQS queue depth (`payments-retry-${ENV}`), CloudFront access logs for receipt downloads.

## Dashboard Layout
### Checkout Health
- Timeseries: `payments.checkout.success_rate` (target ≥ 97% 15m rolling).
- Timeseries: `payments.checkout.sessions_active` vs `payments.checkout.sessions_pending`.
- Table: Top 10 failure reasons using log analytics over last 24h.

### Payment Window & Expiration
- Timeseries: `payments.window.expired_count` with annotations for manual overrides.
- Timeseries: `payments.window.extension_count` / `payments.window.override_count` stacked.
- SLO widget: % of sessions expired without retry (goal < 5%).

### Retry Performance
- Timeseries: `payments.retry.attempt_count` vs `payments.retry.success_rate`.
- Table: Retry backlog (SQS messages visible/in-flight).
- Heatmap: Retry outcomes by attempt number (1,2,3).

### Receipt Generation
- Timeseries: `payments.receipt.render_time_ms` (p95) with threshold 2000ms.
- Timeseries: `payments.receipt.error_count`.
- Table: Recent receipts with download status + CloudFront edge location.

## Alerting & Notifications
- **PagerDuty `Payments Checkout`:** Trigger when checkout success rate <97% for 10 minutes or webhook lag >2 minutes.
- **Slack `#eng-commerce`:** Notify on `payments.window.expired_count > 10` per hour or `payments.retry.failure_count > 5` per 15 minutes.
- **Opsgenie:** Integrate receipt render failure alerts (>3 failures in 5 minutes) for infrastructure escalation.

## Ownership
- **Commerce Backend:** Maintains checkout + retry metrics and EventBridge schedules.
- **Payments SRE:** Owns webhook reliability, SQS scaling, CloudFront distribution.
- **Product Analytics:** Validates Segment event schema and funnel accuracy each release.
- **Support Ops:** Reviews expiration overrides, ensures runbook `docs/runbooks/stripe-payments.md` is followed.
