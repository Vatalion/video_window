# Epic 16 Context: Security & Compliance Operations

**Generated:** 2025-11-04  
**Epic ID:** 16  
**Epic Title:** Security & Compliance Operations  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Secrets Management:** AWS Secrets Manager with automated 90-day rotation
- **RBAC Auditing:** Automated role deviation detection with weekly scans
- **Pen-test Tracking:** Finding → Assignment → Remediation → Verification workflow
- **DSAR Automation:** Data Subject Access Request handling (30-day GDPR SLA)
- **Compliance Framework:** SOC2, PCI-DSS (SAQ A), GDPR, CCPA

### Technology Stack
- Secrets: AWS Secrets Manager (automated rotation)
- CI/CD Security: Snyk, Dependabot (vulnerability scanning)
- PostgreSQL: security_findings, dsar_requests tables
- DSAR: Automated data export to S3 with encryption
- Audit: AWS CloudTrail, security event logs

### Key Integration Points
- AWS Secrets Manager: Secret rotation automation with alerts
- `video_window_server/lib/src/services/security/` - Security services
- RBAC audit: Automated deviation detection and reporting
- DSAR workflow: Data export/delete automation

### Implementation Patterns
- **Secrets Rotation:** Automated 90-day rotation with pre-expiry alerts (7 days)
- **RBAC Audit:** Weekly scans comparing actual vs expected roles, deviation reports
- **Pen-test Tracking:** Jira/Linear integration for finding workflow management
- **DSAR Automation:** Request intake → Data collection → Review → Export/Delete (30-day SLA)

### Story Dependencies
1. **16.1:** Secrets rotation & RBAC auditing (foundation)
2. **16.2:** Pen-test findings tracking & app store policies (parallel with 16.1)
3. **16.3:** DSAR workflow automation (parallel with 16.1, 16.2)

### Success Criteria
- 100% secrets rotated on 90-day schedule
- RBAC deviations detected within 24 hours
- Critical pen-test findings remediated in <30 days
- DSAR requests completed within 30-day GDPR requirement
- Compliance framework documented and auditable

**Reference:** See `docs/tech-spec-epic-16.md` for full specification
