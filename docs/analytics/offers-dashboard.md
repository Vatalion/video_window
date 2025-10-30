# Offers Submission Dashboard

## Overview
Provide unified visibility into the Epic 9 offer submission lifecycle across validation, risk, auction trigger, and cancellation flows.

## Data Sources
- **Datadog**: Metrics emitted by offers services (`offers.validation.duration_ms`, `offers.submission.success_rate`, `offers.cancellation.success_rate`, `offers.auction_trigger.lag_ms`, `offers.risk_check.duration_ms`, `offers.audit.ingest_success_rate`, `offers.audit.export_latency_ms`).
- **Segment**: Client funnel events (`offer_draft_started`, `offer_validation_failed`, `offer_submitted`, `offer_auto_rejected`, `offer_cancelled`, `auction_triggered_from_offer`).
- **EventBridge / SNS**: Offer lifecycle notifications, cancellation alerts, auction triggers routed to downstream services.
- **Kibana**: Structured logs from offers services using index pattern `offers-submission-*`.

## Dashboard Widgets

### Validation Pipeline
- **p95 Validation Duration**: Datadog timeseries of `offers.validation.duration_ms` with alert threshold 400ms.
- **Validation Failures by Rule Code**: Kibana visualization aggregating rule identifiers returned by OPA.
- **Client Validation Latency**: Datadog timeseries `offers.client.validation_latency_ms` (Widget added via Story 9.1).

### Submission & Risk
- **Submission Success Rate**: Datadog SLO widget for `offers.submission.success_rate` (target ≥ 98%).
- **Risk Check Duration**: Datadog timeseries `offers.risk_check.duration_ms` segmented by partner (Stripe, Sift, Plaid).
- **Partner Outage Heatmap**: Kibana saved search highlighting error logs tagged with `partner_outage=true`.

### Auction Trigger
- **Auction Trigger Lag**: Datadog timeseries `offers.auction_trigger.lag_ms` with threshold 1000ms.
- **Auctions Started (24h)**: Datadog query counting EventBridge events `offers.auction.started`.

### Cancellation & Audit
- **Cancellation Success Rate**: Datadog timeseries `offers.cancellation.success_rate` (target ≥ 95%).
- **High-Value Cancellations**: Kibana table filtered where amount ≥ maker auto-reject threshold; tie to Slack alerts.
- **Audit Ingest Health**: Datadog SLO for `offers.audit.ingest_success_rate`.
- **Glacier Export Latency**: Datadog timeseries `offers.audit.export_latency_ms` with annotation on SLA breaches.

### Funnel & Conversion
- **Offer Funnel**: Segment funnel widget tracking `offer_draft_started → offer_submitted → auction_triggered_from_offer`.
- **Validation Failure Reasons**: Segment bar chart by event property `rule_code` for `offer_validation_failed`.

## Alerting
- **Slack**: `#eng-offers` receives Datadog + EventBridge alerts for validation, submission, and cancellation thresholds.
- **PagerDuty**: `Offers Submission` service triggered when submission success <95% for 10 minutes.
- **Opsgenie**: Notified for auction trigger lag >2s sustained over 3 intervals.

## Ownership & Maintenance
- Product Analytics: Configures Segment funnels and ensures event schemas remain in sync with app releases.
- Commerce Backend Team: Maintains Datadog monitors and Kibana dashboards.
- Compliance: Reviews audit widgets monthly and signs off on Glacier export health.
