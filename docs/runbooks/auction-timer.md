# Auction Timer Runbook

## Summary
Guides on-call engineers through diagnosing and resolving issues with the auction timer, soft-close extensions, and state transitions introduced in Epic 10.

## Service Overview
- **Scheduler:** AWS EventBridge rule (`auction-timer-tick`) invokes Serverpod task `auctionTimerTickTask` every minute.
- **Serverpod Services:** `auction_timer_service.dart`, `soft_close_service.dart`, `auction_state_service.dart` orchestrate timer persistence, drift correction, and notifications.
- **Data Stores:** PostgreSQL tables (`auction_timer_state`, `auction_soft_close_events`), Redis streams (`auction_timer_commands`), S3 for audit logs.
- **Alerts:** Datadog monitors (`auctions.timer.*`), Segment event throttles, SNS notifications to makers/buyers.

## Quick Links
- Dashboard: `docs/analytics/auction-timer-dashboard.md`
- Logs: Kibana search `index:auction-timer-*`
- PagerDuty Service: Auction Timer
- Slack: `#eng-offers`, `#ops-oncall`

## Initial Triage
1. **Confirm Alert Context:** Identify which monitor fired (drift, scheduler failure, soft-close cap hits) via PagerDuty/Slack message.
2. **Check Dashboard:** Validate metric spike on the Auction Timer dashboard to confirm real incident vs noisy alert.
3. **Inspect Logs:** Use Kibana `auction-timer-*` to review relevant time window; pay attention to `drift_detected`, `scheduler_invoke_failure`, `soft_close_extension_failed` log entries.
4. **Assess Impact:** Determine number of affected auctions; cross-reference with Segment events `auction_timer_resynced` and `auction_state_changed`.

## Common Scenarios
### A. Timer Drift Exceeds Threshold
- **Symptoms:** `auctions.timer.drift_ms` > 300ms, reconciliation events missing.
- **Actions:**
  1. Run Serverpod admin command `auctionTimer:resync` targeting affected auction IDs.
  2. Verify Redis stream backlog; restart worker if command backlog > 1000 entries.
  3. Confirm Datadog drift metric returns <150ms; close alert.

### B. Soft-Close Extensions Failing
- **Symptoms:** Soft-close extensions capped early; Segment `auction_soft_close_extended` drops.
- **Actions:**
  1. Inspect `soft_close_service.dart` logs for threshold errors.
  2. Manually extend auction via Serverpod CLI `softClose:extend <auction_id> <minutes>` if buyer fairness at risk (coordinate with product).
  3. File incident report if manual override executed. Notify maker via SNS template `soft_close_manual_override`.

### C. Scheduler Failures
- **Symptoms:** EventBridge invocation errors, `auctions.scheduler.failures` >0.
- **Actions:**
  1. Check AWS CloudWatch for EventBridge rule suppression or permission issue.
  2. Re-run Terraform module `terraform/auction_timer_scheduler` if configuration drift detected.
  3. Restart Serverpod worker pool (`auction_timer_worker`) using deployment pipeline.
  4. Validate new ticks in logs; ensure backlog drains.

### D. State Transition Stalls
- **Symptoms:** Auctions stuck in `active` beyond end time, inconsistent `auction_state_changed` events.
- **Actions:**
  1. Verify DB state for affected auction (PostgreSQL table `auction_timer_state`).
  2. Trigger Serverpod admin command `auctionState:forceTransition <auction_id> ended` when authorized.
  3. Confirm Segment events and notifications delivered post-transition.

## Escalation
- **Level 1:** Commerce Backend (primary). Response within 15 minutes.
- **Level 2:** Infrastructure (Terraform/EventBridge issues).
- **Level 3:** Product/Operations for manual auction decisions.

## Post-Incident Tasks
- Update incident doc in Confluence `Auction Timer Incidents`.
- Review monitors for tuning; update `docs/analytics/auction-timer-dashboard.md` if new metrics needed.
- Add retrospective notes to `docs/tech-spec-epic-10.md` changelog.

## Verification Checklist
- Drift metric <150ms over last 30 minutes.
- `auctions.scheduler.failures` back to 0.
- Impacted auctions transitioned correctly.
- Segment event volume returned to baseline.
- SNS notifications delivered without retry backlog.

## Contacts
- Commerce Backend Lead: TBD (update quarterly).
- Infra On-Call: via PagerDuty schedule `Infra Primary`.
- Product Ops Liaison: `product-ops@craftvideo.market`.
