# Tech Spec: Epic 17 - Analytics & KPI Reporting

**Epic ID:** 17 | **Created:** 2025-10-31 | **Priority:** Operations (Sprint 9-11)

## Overview
Governed event schema, KPI dashboards, and automated reporting.

## Stories
- Story 17.1: Define Event Schema and Instrumentation
- Story 17.2: Build KPI Pipeline and Dashboards
- Story 17.3: Schedule Reporting and Stakeholder Exports

## Architecture
- Event Collection: Segment SDK
- ETL: Fivetran/Airbyte → BigQuery/Snowflake
- Visualization: Looker/Data Studio
- Reporting: Weekly email digests

## Event Schema (MVP)
```javascript
// Core events
feed_view, story_view, offer_open, bid_place
checkout_start, payment_success, shipping_start, delivery_confirm

// Metadata
user_id, session_id, timestamp, platform, app_version
```

## KPIs Tracked
1. Acquisition: DAU, sign-ups
2. Engagement: Story views, POAL
3. Conversion: Offer-to-bid, bid-to-payment rates
4. Revenue: GMV, marketplace fees, AOV
5. Operations: Shipping SLA, dispute rate

## Tech Stack
- Segment SDK (events)
- ETL: Fivetran → BigQuery
- Dashboards: Looker/Data Studio
- Alerts: Slack/PagerDuty

## Success Metrics
- Event coverage: 100% MVP events
- Data freshness: <24 hours
- Stakeholder satisfaction: >80%

## Related
- [PRD Epic 17](./prd.md#epic-17)
- [Definition of Ready](./process/definition-of-ready.md)

**Status:** Draft | **Owner:** Winston + BMad Master
