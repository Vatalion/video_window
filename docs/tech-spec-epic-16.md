# Tech Spec: Epic 16 - Security & Policy Compliance

**Epic ID:** 16 | **Created:** 2025-10-31 | **Priority:** Operations (Sprint 9-11)

## Overview
Maintain security posture with secrets rotation, RBAC auditing, pen-test tracking, and DSAR workflows.

## Stories
- Story 16.1: Implement Secrets Rotation and RBAC Auditing
- Story 16.2: Track Pen-Test Findings and App Store Policies  
- Story 16.3: Handle Data Subject Requests (DSAR)

## Architecture
- Secrets Management: AWS Secrets Manager (90-day rotation)
- RBAC Auditing: Automated deviation reports
- Pen-Test Tracking: Findings dashboard
- DSAR Workflow: Automated export/delete (30-day SLA)

## Database Schema
```sql
CREATE TABLE security_findings (
  id UUID PRIMARY KEY,
  finding_type VARCHAR(50),
  severity VARCHAR(20),
  owner UUID,
  status VARCHAR(20)
);

CREATE TABLE dsar_requests (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  request_type VARCHAR(20),
  status VARCHAR(50),
  completed_at TIMESTAMPTZ
);
```

## Tech Stack
- AWS Secrets Manager
- CI/CD scanning (Snyk, Dependabot)
- PostgreSQL + S3

## Success Metrics
- Secrets rotation: 100% compliance
- Pen-test remediation: <30 days (critical)
- DSAR completion: <30 days (GDPR)

## Related
- [PRD Epic 16](./prd.md#epic-16)
- [Definition of Ready](./process/definition-of-ready.md)

**Status:** Draft | **Owner:** Winston + BMad Master
