# Epic 17 Context: Analytics & Reporting

**Generated:** 2025-11-04  
**Epic ID:** 17  
**Epic Title:** Analytics & Reporting  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Event Collection:** Segment SDK (client + server-side)
- **ETL Pipeline:** Fivetran/Airbyte → BigQuery/Snowflake data warehouse
- **Visualization:** Looker/Data Studio dashboards for stakeholders
- **Reporting:** Automated weekly stakeholder exports via email
- **Governance:** Event schema versioning with validation and registry

### Technology Stack
- Events: Segment SDK (Flutter + Serverpod integration)
- ETL: Fivetran → BigQuery (real-time sync, <24h freshness)
- Visualization: Looker/Data Studio for interactive dashboards
- Alerts: Slack/PagerDuty for anomaly detection
- Governance: Schema registry with JSON Schema validation

### Key Integration Points
- Segment SDK: Event instrumentation across client and server
- BigQuery: Data warehouse for analytics and reporting
- Looker: Dashboard and self-service analytics tool
- Alerting: Anomaly detection with Slack/PagerDuty integration

### Implementation Patterns
- **Event Schema:** Versioned schema (v1, v2) with backward compatibility and validation
- **ETL Pipeline:** Real-time sync with <24h data freshness guarantee
- **KPI Dashboards:** Acquisition, engagement, conversion, revenue, operations metrics
- **Automated Reporting:** Weekly exports to stakeholders (PDF/CSV) via scheduled jobs

### Story Dependencies
1. **17.1:** Event schema definition & instrumentation (foundation)
2. **17.2:** KPI pipeline & dashboard development (depends on 17.1)
3. **17.3:** Automated reporting & stakeholder exports (depends on 17.1, 17.2)

### Success Criteria
- 100% of MVP events instrumented and validated
- Data freshness <24 hours (P95)
- Dashboards accessible to all stakeholders
- Weekly reports automated and delivered on schedule
- Event schema validated at instrumentation time

**Reference:** See `docs/tech-spec-epic-17.md` for full specification
