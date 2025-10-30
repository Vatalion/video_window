# Auction Timer Dashboard

## Overview
Track health of the auction timer, soft-close extensions, and state transitions defined in Epic 10.

## Data Sources
- **Datadog:** Metrics `auctions.timer.drift_ms`, `auctions.timer.tick_delay_ms`, `auctions.soft_close.trigger_count`, `auctions.soft_close.cap_hits`, `auctions.state.transition_count`, `auctions.scheduler.failures`, `auctions.websocket.active_connections`.
- **Segment:** Events `auction_timer_started`, `auction_soft_close_extended`, `auction_state_changed`, `auction_timer_resynced`, `auction_timer_drift_warning`.
- **Kibana:** Index `auction-timer-*` capturing scheduler logs, reconciliation adjustments, manual overrides.
- **SNS/EventBridge:** Auction state and soft-close override notifications.

## Dashboard Layout
### Timer & Drift
- Timeseries: `auctions.timer.drift_ms` (p95), alert threshold 250ms.
- Timeseries: `auctions.timer.tick_delay_ms` with target <1200ms.
- Table: Top auctions by drift detected in last 24h.

### Soft-Close
- Counter: `auctions.soft_close.trigger_count` per hour. Annotate when cap reached.
- Bar chart: Extensions by reason (auto vs manual overrides).
- Timeseries: `auctions.soft_close.cap_hits` with Slack alert >3/day.

### State Transitions
- Timeseries: `auctions.state.transition_count` segmented by state.
- Funnel: `auction_timer_started → auction_state_changed(active) → auction_state_changed(accepted|ended)` (Segment).
- Table: SNS delivery success for maker/buyer notifications.

### Reliability & Operations
- Timeseries: `auctions.scheduler.failures` (should remain 0).
- Gauge: WebSocket active connections vs capacity.
- Synthetic check results from `auction_timer_drift_test` (success/fail) with links to logs.

## Alerting
- **Slack `#eng-offers`:** Drift p95 > 300ms, soft-close cap hits spike, scheduler failure.
- **PagerDuty `Auction Timer`:** Timer success <99%, reconciliation failures >3 per hour.
- **Opsgenie:** WebSocket disconnect surge >20% of active clients.

## Ownership
- **Commerce Backend:** Maintains Datadog monitors and reconciliation tasks.
- **Product Analytics:** Validates Segment funnels and event schemas each release.
- **Operations:** Reviews dashboard during daily stand-up, coordinates incident response with runbook `docs/runbooks/auction-timer.md`.
