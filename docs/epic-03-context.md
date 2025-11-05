# Epic 03 Context: Observability & Compliance Baseline

**Generated:** 2025-11-04  
**Epic ID:** 03  
**Epic Title:** Observability & Compliance Baseline  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Logging:** Structured logging with OpenTelemetry + CloudWatch
- **Metrics:** Prometheus + Grafana + CloudWatch integration
- **Privacy:** GDPR/CCPA compliance framework
- **Backups:** AWS Backup + PostgreSQL PITR
- **Monitoring:** Grafana dashboards + alerting

### Technology Stack
- OpenTelemetry + CloudWatch Logs
- Prometheus + Grafana + CloudWatch Metrics
- Custom compliance framework for GDPR/CCPA
- AWS Backup + PostgreSQL Point-in-Time Recovery

### Key Integration Points
- `video_window_server/lib/src/services/logger.dart` - Structured logging
- `video_window_server/lib/src/services/metrics.dart` - Metrics collection
- `video_window_server/lib/src/compliance/` - Privacy framework
- Grafana dashboards for operational visibility

### Implementation Patterns
- **Structured Logging:** JSON format with trace context
- **Distributed Tracing:** OpenTelemetry spans across services
- **Privacy:** Data classification and retention policies
- **Backup:** Automated daily backups with 30-day retention

### Story Dependencies
1. **03.1:** Logging & metrics (foundation)
2. **03.2:** Privacy & legal disclosures (parallel with 03.1)
3. **03.3:** Data retention & backups (depends on all)

### Success Criteria
- All production logs structured and searchable
- Metrics dashboards operational with alerting
- GDPR/CCPA compliance documented and validated
- Backups tested with <4 hour recovery time

**Reference:** See `docs/tech-spec-epic-03.md` for full specification
