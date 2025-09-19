# Video Window Data Instrumentation Reference

## Purpose
Document canonical analytics events, properties, and data flows so engineering and data partners ship instrumentation that aligns with the PRD metrics, privacy standards, and experimentation backlog.

## Ownership
- **Product Analytics Lead:** TBD (assign before Phase 0 alpha)
- **Data Engineering:** TBD
- **PM:** John (Product Manager)

## Event Design Principles
1. **Decision-backed:** Every event must support a dashboard, alert, or experiment decision documented in the PRD.
2. **Privacy-aware:** Collect only data required to monitor KPIs; respect opt-out preferences and ensure PII masking where possible.
3. **Consistent naming:** Use snake_case, with verb-noun structure (e.g., `story_published`, `checkout_initiated`).
4. **Schema versioning:** Increment `schema_version` when adding/removing properties; maintain changelog below.
5. **Testability:** Provide unit/integration tests or QA scripts that validate event firing and property payloads.

## Event Catalog (MVP)
| Event | Description | Key Properties | Triggered By | Notes |
|-------|-------------|----------------|--------------|-------|
| `creator_onboarding_completed` | Creator finishes onboarding flow and awaits approval. | `creator_id`, `craft_disciplines`, `fulfillment_type`, `timestamp` | Client | Send once per approval cycle; include feature flag state. |
| `story_draft_saved` | Creator saves story draft. | `creator_id`, `story_id`, `media_count`, `is_object_story`, `timestamp` | Client | Fire on autosave and manual save; include draft count metric. |
| `story_published` | Story submitted for moderation or approved to go live. | `creator_id`, `story_id`, `submission_state`, `price`, `inventory_state`, `timestamp` | Client/Server | Distinguish `submitted` vs `approved`. |
| `feed_story_impression` | Viewer sees a story in the vertical feed. | `viewer_id`, `story_id`, `position`, `dwell_ms`, `auto_play_state` | Client | Sample rate ≤10% if volume becomes high; ensure dwell > 200ms. |
| `detail_section_interacted` | Viewer expands materials/tools or timeline section. | `viewer_id`, `story_id`, `section_type`, `action` (`expand`, `scroll`, `cta_click`) | Client | Ties to engagement KPI and experimentation backlog. |
| `checkout_initiated` | Viewer begins object checkout. | `viewer_id`, `story_id`, `price`, `inventory_state`, `payment_method` | Client | Distinguish object vs service via `story_type`. |
| `booking_confirmed` | Viewer completes service booking deposit. | `viewer_id`, `story_id`, `price`, `selected_slot`, `service_radius_km` | Server | Include deposit amount and cancellation window. |
| `order_status_updated` | Purchase/booking state change. | `order_id`, `status`, `timestamp`, `actor` | Server | Drives dashboard and operations alerts. |
| `moderation_action_taken` | Moderation decision recorded. | `story_id`, `action`, `moderator_id`, `reason_code`, `timestamp` | Internal tool | Log for transparency report. |
| `support_ticket_created` | Buyer or creator files support ticket. | `ticket_id`, `category`, `sub_category`, `source` (`in_app`, `email`), `timestamp` | Support tooling | Enables support SLA metrics. |

## Property Reference
Describe common property definitions, types, and allowed values.

| Property | Type | Description |
|----------|------|-------------|
| `creator_id` | UUID | Platform-generated identifier for creators (distinct from auth ID). |
| `story_id` | UUID | Unique story identifier, stable across drafts and publishes. |
| `story_type` | enum | `object` or `service`. |
| `inventory_state` | enum | `in_stock`, `low_stock`, `sold_out`, `made_to_order`. |
| `submission_state` | enum | `draft`, `submitted`, `approved`, `rejected`. |
| `status` | enum | `pending`, `confirmed`, `fulfilled`, `cancelled`, `refunded`. |
| `reason_code` | enum | Reference moderation policy codes (see Content & Trust Policy). |

## Data Flow Overview
- Client events captured via Segment (or equivalent) → forwarded to Serverpod for validation → stored in Postgres. Future expansion to warehouse (e.g., Snowflake/BigQuery) once scale warrants.
- Server events emitted directly from Serverpod with consistent schema.
- Dashboard layer (Metabase/Looker) reads from read replica; alerts pipeline pushes to PagerDuty/Slack.

## Governance & Review Cadence
- Weekly analytics sync: ensure instrumentation coverage for upcoming releases.
- Monthly schema review: align on property changes, update this document, and communicate to engineering.
- Quarterly privacy audit: confirm data retention and opt-out handling.

## Change Log
| Date | Version | Description | Owner |
|------|---------|-------------|-------|
| 2025-09-18 | v0.1 | Initial instrumentation reference drafted from PRD. | John |

